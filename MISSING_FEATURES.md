# LittleStars — Missing Backend Features

These features are visible in the Soft Candy design but not yet implemented in the backend.
Frontend placeholders are in place; implement these to complete the product.

## Models

### Profile
- [ ] `streak` (integer, default 0) — daily streak counter
  - Needs: daily cron to reset streaks, increment when all tasks done
- [ ] `face` (string) — avatar face variant (smile/wink/tongue/adult)
  - Currently derived from `color` via `ApplicationHelper#face_for`; add column for per-profile override

### Reward
- [ ] `category` (string, enum) — tela/doce/passeio/brinquedo/experiencia
  - Used for category filter tabs in shop
- [ ] `icon` / `art` (string) — Lucide/Phosphor icon key
  - Used for reward illustrations; currently falls back to "gift"
- [ ] Edit route — `resources :rewards` currently excludes `:edit`/`:update`
  - Parent rewards view has disabled placeholder pencil button

### Redemption
- [ ] Reward delivery confirmation — parent marks redemption as "delivered"
  - New status after `approved`: `:delivered` (after parent physically delivers reward)
  - Route: `PATCH /parent/redemptions/:id/deliver`

### ProfileTask
- [ ] `proof_image` — photo proof attachment (ActiveStorage)
  - `Family#require_photo_proof` rules flag
  - Upload flow for kid, review in parent approvals
- [ ] `rejection_note` (text) — stored rationale when rejecting a mission
- [ ] `active?` — GlobalTask currently has no active flag; parent missions table assumes always active
  - Add `active` (boolean, default true) + toggle route `PATCH /parent/global_tasks/:id/toggle_active`

### Family
- [ ] `star_decay` (boolean, default false) — expire unused stars after 30 days
- [ ] `negative_balance` (boolean, default false) — allow kids to go negative
- [ ] `auto_approve_under` (integer, default 0) — auto-approve missions below this star value
- [ ] `require_photo_proof` (boolean, default false)
- [ ] `week_start` (string, default "mon")

### ActivityLog
- [ ] `amount` / `description` fields — currently uses `points` + `title`
  - Dashboard falls back; consider unifying
- [ ] Status field (pending/approved/rejected) — current history view has "Aguardando" and "Rejeitadas" filter chips that show nothing

## Services
- [ ] `ProfileTask::BonusService` — parent grants bonus stars to a kid
  - Creates ActivityLog with `log_type: :bonus`
  - Increments `profile.points`
- [ ] `ProfileTask::RejectWithNoteService` — reject with optional rationale

## Controllers / Routes
- [x] `parent/settings` — added in Phase 8 (minimal, mostly static UI)
  - `GET  /parent/settings`
  - `PATCH /parent/settings` — currently no-op redirect
- [ ] Bulk approve endpoint — `PATCH /parent/approvals/bulk_approve`
  - Approvals view has checkboxes rendered but not wired
- [ ] Co-parent invitation — `/parent/settings` lists parents; invite button inert

## UI Gaps (frontend-only TODOs)
- [ ] Notification bell — badge count, dropdown, read/unread state
- [ ] Profile face selector in kid profile edit form
- [ ] Reward category filter actually filters (currently single active tab, no filtering logic until `Reward#category` lands)
- [ ] History "Aguardando" and "Rejeitadas" filter panels populate (need status field on ActivityLog or join with ProfileTask)
- [ ] Parent rewards edit — disabled placeholder pencil; enable when route lands
- [ ] Parent missions active toggle — currently static CSS pill; wire to toggle_active route
- [ ] Parent settings form submits are no-op — wire fields to Family columns once added
