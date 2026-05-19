# Codebase Concerns

**Analysis Date:** 2026-04-21

---

## Tech Debt

### 1. Missing Database Constraints for Required Fields

**Issue:** Several critical fields lack `NOT NULL` database constraints, relying solely on model validation.

**Files:** 
- `db/migrate/20260419181926_create_profiles.rb` (name, role, avatar)
- `db/migrate/20260419181927_create_global_tasks.rb` (title, points, category, frequency)
- `db/migrate/20260419181929_create_rewards.rb` (title, cost, icon)
- `db/migrate/20260419181930_create_activity_logs.rb` (log_type, title, points)
- `db/migrate/20260419193609_create_redemptions.rb` (points, status)

**Impact:** Database-level data corruption if validation bypassed or direct SQL executed. Rails validations are not enforced at DB layer.

**Fix approach:** Add `null: false` to migrations for all required columns. Create a migration to add constraints to existing columns:
```ruby
change_column :profiles, :name, :string, null: false
change_column :profiles, :role, :integer, null: false
change_column :global_tasks, :title, :string, null: false
change_column :global_tasks, :points, :integer, null: false
change_column :rewards, :title, :string, null: false
change_column :rewards, :cost, :integer, null: false
change_column :activity_logs, :points, :integer, null: false
change_column :activity_logs, :title, :string, null: false
change_column :redemptions, :status, :integer, null: false
change_column :redemptions, :points, :integer, null: false
```

---

### 2. Missing Enum Validation in ActivityLog

**Issue:** `ActivityLog.log_type` enum has values `:earn` and `:redeem`, but `Rewards::RejectRedemptionService` uses `:adjust` (line 19 of `app/services/rewards/reject_redemption_service.rb`), which is not defined in the enum.

**Files:** `app/models/activity_log.rb`, `app/services/rewards/reject_redemption_service.rb:19`

**Impact:** Non-existent enum value will fail at runtime or store as invalid integer. Queries filtering by log_type will not include refund entries.

**Fix approach:** Either (a) add `:adjust` to `ActivityLog` enum definition, or (b) use `:earn` with negative points for refunds, maintaining the 2-value enum. Option (b) is preferred to avoid schema bloat.

---

### 3. Inconsistent Redemption Approval Flow Logic

**Issue:** `Rewards::ApproveRedemptionService` (lines 1-22) changes status to `:approved` but **does not decrement points** from the profile. Points were already decremented in `Rewards::RedeemService` at request time. But if approval is rejected, `Rewards::RejectRedemptionService` increments points back. This asymmetry creates a two-phase commit that can leave orphaned redemptions if parent approval actions fail mid-transaction.

**Files:**
- `app/services/rewards/redeem_service.rb` (decrements immediately)
- `app/services/rewards/approve_redemption_service.rb` (only updates status)
- `app/services/rewards/reject_redemption_service.rb` (increments back)

**Impact:** If approval transaction fails after status update but before broadcast, redemption is stuck in `:approved` state but points have not been confirmed as spent. Kid sees approval happened but points weren't deducted. Inconsistency between Redemption.status and ActivityLog ledger.

**Fix approach:** Document this as intentional 2-phase flow (request → approve/reject) similar to task approval. Add comments in ApproveRedemptionService explaining that points were already deducted in RedeemService. Add error recovery tests confirming both states are consistent after exception.

---

## Known Bugs

### 1. Potential N+1 in DailyResetService

**Issue:** `Tasks::DailyResetService` line 24 calls `global_task.family.profiles.select(&:child?)` inside a `find_each` loop. The `family` association is already eager-loaded (line 14: `includes(family: :profiles)`), but `select(&:child?)` filters in Ruby, not SQL. This works but is inefficient; better to filter at SQL level.

**Symptoms:** For families with many profiles, reset job is slower than necessary and loads all profiles into memory.

**Files:** `app/services/tasks/daily_reset_service.rb:24`

**Trigger:** Run daily reset job with a large family (100+ profiles).

**Workaround:** None currently; inefficiency is silent but observable in logs.

**Fix approach:** Use SQL scope instead of Ruby select:
```ruby
global_task.family.profiles.where(role: :child).each do |child|
```
Or refactor to avoid re-loading family per task:
```ruby
family.profiles.child.each do |child|
  family.global_tasks.each { |task| ... }
end
```

---

### 2. Missing Null Check in SessionsController

**Issue:** `SessionsController#index` (line 6) calls `Family.includes(:profiles).first` with no nil guard. If no family exists in database, `@family` is nil, and `@profiles = @family&.profiles || []` succeeds but view may crash if it tries to render profile selection without families.

**Symptoms:** If database is empty (e.g., failed seed or test isolation issue), index view renders but with no families to select, then user sees blank page or 500 error depending on view implementation.

**Files:** `app/controllers/sessions_controller.rb:6-7`, view expects `@profiles` to be non-nil

**Trigger:** Navigate to `/` after intentionally deleting all families.

**Workaround:** Create at least one family via `rails console`.

**Fix approach:** Add guard in controller or view; consider adding a seed check or onboarding flow for fresh installations.

---

## Security Considerations

### 1. Session-Based Profile Selection (No Real Auth)

**Risk:** MVP uses only `session[:profile_id]` with no authentication. Any user can set any profile_id in session via direct session manipulation or forged POST to `/sessions#create` without password. No CSRF protection on `/sessions#create` (line 2 skips token verification).

**Files:** `app/controllers/sessions_controller.rb`, `app/controllers/application_controller.rb:13`

**Current mitigation:** 
- Family scoping in `Authenticatable#authorize_family!` (defensive check in some controllers)
- Request specs verify cross-family isolation (`spec/requests/security/family_scoping_spec.rb`)

**Recommendations:**
1. **Add a family-level password or PIN** for local MVP testing (not production auth).
2. **Keep CSRF token skipping for POST /sessions but add rate limiting** to prevent brute-force profile switching.
3. **Log profile changes** for audit trail: add entry in ActivityLog when `session[:profile_id]` changes.
4. **Pre-production:** Implement real authentication (OAuth, bcrypt, etc.) before any internet-facing deployment.

---

### 2. Missing CSRF Protection on Session Routes

**Risk:** Line 2 of `SessionsController` skips CSRF token verification for create/destroy. This allows a child to switch profiles if they visit an attacker's link. Post-redirect to `sessions#create?profile_id=PARENT_ID` via forged form from external site would elevate kid to parent role.

**Files:** `app/controllers/sessions_controller.rb:2`

**Current mitigation:** Reliance on same-site cookies (Rails default SameSite=Lax); assumes attacker cannot inject from same domain.

**Recommendations:**
1. **Re-enable CSRF for sessions** (remove skip unless there's a specific integration need documented).
2. **If skip is necessary**, add rate limiting and log all profile switches.
3. **Add an explicit user confirmation step** before switching to a parent profile (e.g., "Switch to Admin? This action is logged.").

---

### 3. Direct Profile ID Lookup in SessionsController#create

**Risk:** Line 11 of `sessions_controller.rb` — `Profile.find(params[:profile_id])` — does no family scoping at the HTTP layer. A child in family A could guess a profile ID in family B and set their session to that profile. The `authorize_family!` check in controllers would reject the subsequent read, but a parent could theoretically manipulate their own family's data.

**Files:** `app/controllers/sessions_controller.rb:11`

**Current mitigation:** 
- `authorize_family!` helper protects most controllers.
- `require_parent!` and `require_child!` guards prevent cross-role escalation within same family.

**Recommendations:**
1. **Add family context check in SessionsController#create**: verify that the profile being selected belongs to a family the user is already in (requires pre-existing auth context or family identifier).
2. **For MVP simplicity:** assume one family per installation; enforce `Family.first` and warn if more than one family exists.
3. **Document assumption** in CLAUDE.md: "MVP supports single family per installation. Multi-family support requires auth refactor."

---

## Performance Bottlenecks

### 1. Broadcast on Every ProfileTask Status Change

**Issue:** `ProfileTask#after_update_commit :remove_from_kid_dashboard` (line 13 of `app/models/profile_task.rb`) broadcasts to Turbo channel on every status update. For a family with 5+ children and 10+ daily tasks, each approval generates 1+ broadcast. High approval throughput (parent batch-approving) could saturate Solid Cable adapter.

**Symptoms:** Noticeable UI lag when parent approves multiple tasks rapidly; cable backlog in logs.

**Files:** `app/models/profile_task.rb:12-13`, `app/models/profile.rb:9`

**Impact:** Low for MVP (few users), but scales poorly. Each save triggers `broadcast_update_to` or `broadcast_remove_to`.

**Improvement path:**
1. **Batch broadcasts**: Instead of per-task, collect updates and broadcast once per request (use ActiveSupport::Notifications or custom service hook).
2. **Conditional broadcasts**: Only broadcast if status actually changed (guard with `saved_change_to_status?` — already present but check if `saved_change_to_points?` in Profile also broadcasts unnecessarily).
3. **For large families**, consider caching or periodic polling instead of real-time streams for non-critical updates.

---

### 2. Missing Index on Family Scoping Queries

**Issue:** Controllers frequently query `current_profile.family.profile_tasks`, `family.global_tasks`, etc. Schema has indices on `family_id` at table level (`index_global_tasks_on_family_id`, etc.) but no composite index on `(family_id, status)` or `(family_id, role)` for fast filtering within a family.

**Symptoms:** Parent approval index page loads slowly if family has 1000+ profile_tasks across all children. Each query full-scans the profile_tasks table filtered by family_id.

**Files:** All controllers in `app/controllers/{parent,kid}/` use `current_profile.family.X`

**Impact:** Negligible for MVP (small test families), but blocks scaling to real multi-child families (10+ kids, 500+ tasks/month).

**Improvement path:**
1. **Add composite indices:**
   ```ruby
   add_index :profile_tasks, [:family_id, :status], name: "index_profile_tasks_on_family_id_and_status"
   add_index :profiles, [:family_id, :role], name: "index_profiles_on_family_id_and_role"
   ```
2. **Use EXPLAIN ANALYZE** on slow controllers to verify query plans.
3. **Profile queries in production** before large-scale testing.

---

### 3. Eager Loading Not Consistently Applied

**Issue:** Service objects and controllers sometimes load related records without `includes()`, causing N+1 queries. Example: `Tasks::DailyResetService` eagerly loads `family: :profiles` (line 14) but then calls `global_task.family.profiles` again inside loop (line 24), which is already loaded but method doesn't short-circuit.

**Files:** `app/services/tasks/daily_reset_service.rb:14,24`, other services

**Impact:** Unnecessary DB queries; especially bad in batch jobs.

**Improvement path:** Audit all service objects and controllers for N+1 patterns. Use `bullet` gem to detect in tests/dev. Document eager-loading strategy in CONVENTIONS.md.

---

## Architectural Friction

### 1. Dual Transaction Phases for Redemptions

**Issue:** Redemption flow is intentionally split: `RedeemService` decrements points immediately (request time), `ApproveRedemptionService` confirms status later (approval time). This mirrors task approval but violates "single command = single transaction" principle.

**Impact:** Adds conceptual complexity. If RedeemService succeeds but ApproveRedemptionService never runs, points are deducted indefinitely. Requires careful testing of edge cases (family deleted, profile deleted, etc.).

**Suggestion:** Document this as a **deliberate design choice** in TECHSPEC.md with rationale. Consider adding an admin endpoint to "finalize" or "cancel" orphaned redemptions.

---

### 2. Profile Broadcast Channel Uses Profile ID, Not Family

**Issue:** `Profile#broadcast_points` (line 26 of `app/models/profile.rb`) broadcasts to `self` (target: "profile_points_#{id}"), which targets individual profile update. But `ProfileTask#broadcast_approval_count` (line 20 of `app/models/profile_task.rb`) broadcasts to family channel. Inconsistency in broadcast targets makes it unclear which updates are per-profile vs. per-family.

**Impact:** Confusing to reason about real-time state. Kid's wallet update goes to kid's channel; parent's approval count goes to family's channel. Not a bug but architectural inconsistency.

**Suggestion:** Standardize broadcast targets. Either all to family channel, or all to individual + aggregate. Document in ARCHITECTURE.md.

---

## Scaling Limits

### 1. Single Family Assumption

**Current capacity:** 1 family per installation (enforced by `Family.first` in SessionsController#index).

**Limit:** If feature expands to multi-family SaaS, major refactor needed:
- Session auth must carry family context.
- All queries must filter by family.
- Dashboard views must list families.

**Scaling path:** 
1. Add family_id to session (line 12 of sessions_controller.rb: `session[:family_id] = @profile.family_id`).
2. Update all queries to scope by `current_family`.
3. Build family management UI.

---

### 2. PostgreSQL Array Column for days_of_week

**Current capacity:** GlobalTask.days_of_week is a PG string array (`days_of_week` varchar[] default: []). Works for MVP but doesn't scale well for:
- Querying "all tasks scheduled for Monday" (requires array containment check: `days_of_week @> ARRAY['1']`).
- Indexing (array indices are slow).

**Limit:** With 1000+ tasks and frequent filtering by day, index scans become expensive.

**Scaling path:**
1. Create a `GlobalTaskSchedules` join table: `global_task_id, day_of_week (integer)`.
2. Migrate data from array to rows.
3. Query becomes simple: `where(day_of_week: 1)` — fast index scan.

---

### 3. Solid Queue in Single Process

**Current capacity:** Solid Queue runs embedded in Puma when configured (per CLAUDE.md). Works for dev/test but blocks production scaling.

**Limit:** Cannot scale beyond one web process without dedicated worker pool. If multiple Puma instances are deployed, queued jobs may run on multiple processes, causing duplicate executions.

**Scaling path:**
1. Extract Solid Queue to separate service (`bin/jobs` or systemd service).
2. Configure multiple Puma instances to share queue database.
3. Monitor for duplicate job execution (daily reset running twice at midnight).

---

## Dependencies at Risk

### 1. ViewComponent 4.7 Major Version Stability

**Risk:** ViewComponent is pre-1.0 (currently 4.7). Breaking changes possible in minor versions. The project heavily uses VC for all UI (`app/components/`).

**Impact:** Gemfile.lock pins 4.7, but `bundle update` might pull 5.0 with incompatibilities.

**Recommendation:** 
1. Monitor ViewComponent releases weekly.
2. Test major version updates in a branch before committing.
3. Document known incompatibilities in CHANGELOG.md.

---

### 2. Solid Queue Maturity

**Risk:** Solid Queue is new (Rails 8.x native). Fewer real-world deployments than Sidekiq/Resque. Production bugs may emerge.

**Impact:** If scheduling bugs discovered, fallback is needed (cron jobs, manual scheduling).

**Recommendation:**
1. **For MVP:** acceptable risk (small audience).
2. **Before production:** evaluate against Sidekiq for stability/observability.
3. **Implement monitoring:** alert if daily reset job doesn't run by 12:05 AM.

---

### 3. Propshaft (Asset Pipeline)

**Risk:** Propshaft is Rails 8's new asset pipeline (experimental), replacing Sprockets. Smaller community, less battle-tested for complex asset scenarios.

**Impact:** If Propshaft breaks Tailwind or Stimulus integration, debugging may be difficult.

**Recommendation:**
1. **For MVP:** Propshaft is stable enough; Tailwind integration documented.
2. **If issues arise:** can revert to Sprockets (Gemfile change).
3. **Monitor compatibility** with Tailwind v4 (used here).

---

## Missing Critical Features

### 1. Data Retention / Cleanup Policy

**Issue:** No mechanism to archive or delete old activity logs, expired redemptions, or completed profile tasks. Database will grow unbounded.

**Impact:** Over years, activity_logs and profile_tasks tables become bloated, slowing queries.

**Recommendation:**
1. Add a rake task to archive/delete activity logs > 1 year old (use Solid Queue scheduled job).
2. Document retention policy in README.md (e.g., "Keep 12 months of history").
3. Add monitoring to track table sizes.

---

### 2. Data Export / Backup

**Issue:** No backup strategy documented. Database volume is small (MVP), but if production deployment happens, no backup/restore procedure exists.

**Recommendation:**
1. Document backup approach in DEPLOYMENT.md (e.g., Kamal backup hooks, pg_dump).
2. For Kamal: add pre-deploy db backup step.
3. Test restore procedure quarterly.

---

### 3. Error Recovery for Partial Redemptions

**Issue:** If `ApproveRedemptionService` fails after status update but before activity log create, redemption is stuck in `:approved` state. No admin tool to recover.

**Recommendation:**
1. Add admin panel or rake task to list orphaned redemptions.
2. Implement idempotent service calls (safe to retry).
3. Add data consistency check in admin dashboard.

---

## Test Coverage Gaps

### 1. Untested Edge Case: Profile Points Go Negative After Approve

**Issue:** `Tasks::ApproveService` increments points without checking balance first. Theoretically, if points validation is removed, a parent could approve and give a profile negative points, violating the invariant `points >= 0`.

**Files:** `app/services/tasks/approve_service.rb:18`

**Risk:** Low (validation present on model), but database constraint would be better.

**Test gap:** No spec that verifies points cannot go negative via approve path.

**Fix:** Add test in `spec/services/tasks/approve_service_spec.rb` or ensure model validation is thoroughly tested with negative edge cases.

---

### 2. Untested Broadcast Failures

**Issue:** Services broadcast Turbo updates, but specs don't verify broadcast side effects (no `allow(Turbo::StreamsChannel).to receive` mocks).

**Files:** All service specs in `spec/services/`

**Risk:** Broadcast failures in production go undetected. Real-time updates silently fail.

**Test gap:** No test mocking Turbo::StreamsChannel to verify broadcast calls.

**Fix:** Add shared examples or helper methods to assert broadcasts in service specs:
```ruby
expect(Turbo::StreamsChannel).to have_received(:broadcast_update_to)
```

---

### 3. Untested Session Hijacking Scenario

**Issue:** No spec verifies that setting `session[:profile_id]` to another family's profile ID causes a 404 or redirect.

**Files:** `spec/requests/security/family_scoping_spec.rb` has cross-family access tests but not explicit session hijacking.

**Risk:** Medium (family scoping tested, but session creation not explicitly guarded).

**Test gap:** No test in `SessionsController` request specs that verifies `POST /sessions profile_id:FOREIGN_PROFILE` fails gracefully.

**Fix:** Add spec to `spec/requests/sessions_spec.rb`:
```ruby
it "rejects profile_id from another family" do
  post "/sessions", params: { profile_id: other_family_child.id }
  # Should succeed but set session; subsequent requests should 404
  follow_redirect!
  # Or add pre-check in controller
end
```

---

## Summary: Severity Ranking

| Severity | Item | Category |
|----------|------|----------|
| **CRITICAL** | Missing `NOT NULL` DB constraints | Tech Debt |
| **CRITICAL** | CSRF bypass on sessions (role escalation risk) | Security |
| **HIGH** | ActivityLog enum mismatch (`:adjust` undefined) | Tech Debt |
| **HIGH** | Redemption approval flow inconsistency | Architectural |
| **MEDIUM** | N+1 in DailyResetService | Performance |
| **MEDIUM** | Session-based auth with no real credentials | Security |
| **MEDIUM** | Single family assumption (scaling limit) | Scaling |
| **MEDIUM** | No backup/data retention policy | Missing Feature |
| **LOW** | Broadcast channel naming inconsistency | Architecture |
| **LOW** | ViewComponent pre-1.0 version risk | Dependencies |

---

*Concerns audit: 2026-04-21*
