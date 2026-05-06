# Project Review — Action Items

Source: 5-agent parallel review (2026-05-06).
Order: CRITICAL → HIGH → QUICK WIN → TEST → TECH DEBT.

## CRITICAL

- [x] **C1** — Migrate `Auth::CreateFamily`, `Auth::CreateProfile`, `Auth::ResetPin` to `ApplicationService::Result` contract (drop `OpenStruct`)
- [x] **C2** — Move broadcasts in `Rewards::RedeemService` + `Tasks::ApproveService` to `after_commit` (avoid broadcast on rolled-back state)
- [x] **C3** — PIN brute-force: 6-digit PIN OR exponential backoff + lockout in `ProfileSessionsController`
- [x] **C4** — Validate `assigned_profile_ids` in `Parent::GlobalTasksController` belong to `current_family` (model-level validator on `GlobalTask`)

## HIGH

- [x] **H1** — `Parent::ApprovalsController#approve_all`: lock `ProfileTask` inside TX (`lock.find_by`) to prevent double-credit (fixed at service layer in `Tasks::ApproveService`)
- [x] **H2** — `Kid::WalletController#index`: replace `.load` + Ruby filter with scoped DB query (`.includes(:profile)`, `.where(created_at >=)`, `.limit`)
- [x] **H3** — `Parent::DashboardController`: preload `:wishlist_reward` on `@children` to kill N+1 (verified — already preloaded; agent over-flagged)
- [x] **H4** — Migration: composite indexes
  - `profiles(family_id, role)`
  - `redemptions(profile_id, status)`
  - `activity_logs(profile_id, log_type)`
- [x] **H5** — `InvitationsController`: restore CSRF verification on POST routes (verified — `ApplicationController#protect_from_forgery with: :exception` not skipped; agent over-flagged)
- [x] **H6** — Spec coverage: `Rewards::ApproveRedemptionService` + `Rewards::RejectRedemptionService` (refund rollback paths)

## QUICK WIN

- [x] **Q1** — Remove retired `--c-violet` / `--c-violet-soft` / `--c-violet-dark` from `theme.css`
- [x] **Q2** — `Ui::SmileyAvatar`: migrate `COLOR_MAP` raw hex → CSS tokens via `palette_vars(color)` returning var() refs
- [x] **Q3** — `Ui::StarValue`: move gradient hex to `theme.css` tokens (`--star-grad-light`, `--star-grad-dark`, `--star-grad-pale`)
- [ ] **Q4** — Email templates: extract inline hex to `app/assets/stylesheets/email.css` with var() refs
- [x] **Q5** — Replace `focus:outline-none` in `kid/dashboard/_pending_card.html.erb` + `parent/global_tasks/_form.html.erb` with `focus-visible:ring-2`
- [ ] **Q6** — Extract `shared/_pwa_shell.html.erb` from kid + parent layouts
- [x] **Q7** — `Tasks::CompleteService#last_pending_task_for_today?`: replace `.count.zero?` with `.none?`

## TEST GAPS

- [x] **T1** — Add concurrent-approval spec to `Tasks::ApproveService` (mirror redeem race-condition pattern)
- [ ] **T2** — Add e2e spec: parent create task → kid complete → parent approve → ledger entry
- [ ] **T3** — Add ViewComponent specs for: `Ui::Modal`, `Ui::Drawer`, `Ui::PinModal`, `Ui::FormSection`, `Ui::ProfilePicker`

## TECH DEBT (lower priority — flagged, not solved this pass)

- [ ] **D1** — Dedupe streak calc: `Kid::DashboardController#compute_streak` ↔ `Streaks::CheckService`
- [ ] **D2** — `Family#after_create` → `Categories::SeedDefaultsService` rescue/retry
- [ ] **D3** — Verify ActionCable `connection_identification` enforces profile match for `"kid_#{id}"` channel
- [ ] **D4** — Solid Queue: `JOB_CONCURRENCY` ENV tuning; uncomment `cache.yml` `max_age`

---

## Progress Log

(Each completed item gets timestamp + commit SHA below.)
