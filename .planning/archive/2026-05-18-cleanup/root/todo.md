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
- [x] **Q4** — Email templates: centralize inline hex via `EmailHelper#email_token` (CSS vars are unsupported by most email clients, so values stay inline but flow through one source of truth)
- [x] **Q5** — Replace `focus:outline-none` in `kid/dashboard/_pending_card.html.erb` + `parent/global_tasks/_form.html.erb` with `focus-visible:ring-2`
- [x] **Q6** — Extract `shared/_pwa_shell.html.erb` from kid + parent layouts
- [x] **Q7** — `Tasks::CompleteService#last_pending_task_for_today?`: replace `.count.zero?` with `.none?`

## TEST GAPS

- [x] **T1** — Add concurrent-approval spec to `Tasks::ApproveService` (mirror redeem race-condition pattern)
- [x] **T2** — Add e2e spec: parent create task → kid complete → parent approve → ledger entry (verified — `spec/system/full_mission_flow_spec.rb` already covers the loop)
- [x] **T3** — Add ViewComponent specs for: `Ui::Modal`, `Ui::Drawer`, `Ui::PinModal`, `Ui::FormSection`, `Ui::ProfilePicker` (also fixed pre-existing FormSection bug where `class:` option was clobbered by an empty `super()`)

## TECH DEBT (lower priority — flagged, not solved this pass)

- [x] **D1** — Dedupe streak calc: extracted `Profile#streak_days` consumed by both `Kid::DashboardController` and `Streaks::CheckService`
- [x] **D2** — `Family#after_create` → migrate `Categories::SeedDefaultsService` to `ApplicationService`; callback now logs + raises `Rollback` on seed failure (no half-created family)
- [x] **D3** — Verify ActionCable `connection_identification` enforces profile match for `"kid_#{id}"` channel (verified — no custom channel; Rails uses signed Turbo Stream identifiers, only server-rendered subscriptions can subscribe)
- [x] **D4** — Solid Queue: `JOB_CONCURRENCY` ENV tuning (already wired in `config/queue.yml`); uncommented `cache.yml` `max_age` to enforce 60-day retention

---

## Progress Log

(Each completed item gets timestamp + commit SHA below.)
