# Phase 6: Wishlist & Goal Tracking - Context

**Gathered:** 2026-04-30
**Status:** Ready for planning
**Source:** Inline brief (user-authored design decisions)

<domain>
## Phase Boundary

This phase introduces a **wishlist goal** mechanic. Each child profile can pin **exactly one** existing `Reward` as their savings goal. The kid dashboard renders a `Ui::WishlistGoal` card showing the live progress bar (`profile.points / reward.cost`), the remaining stars, and a redeem CTA when funded. Parents see each kid's current wishlist on the parent profile show page.

**In scope**
- Single-goal-per-kid model (no multi-pin / no priority list yet)
- Pin/unpin from `kid/rewards#index`
- Live update of progress on `points` change (Turbo Stream broadcast from existing services)
- Auto-clear wishlist when the pinned reward is redeemed
- Parent visibility (read-only): augment `Ui::KidProgressCard` on `parent/dashboard#index` (NOT `parent/profiles#show` — that action does not exist in `config/routes.rb`)

**Out of scope**
- Multiple wishlist items, priority ranking, parent-curated wishlists
- Social/sharing features, kid-to-kid wishlist visibility
- Redeem auto-trigger (kid still taps redeem manually; we just surface the CTA when funded)
- Notification/email when goal reached (deferred — push reminders are a separate phase)

</domain>

<decisions>
## Implementation Decisions

### Data model
- Add `wishlist_reward_id` (nullable foreign key) to `profiles` table referencing `rewards.id`
- `belongs_to :wishlist_reward, class_name: "Reward", optional: true` on `Profile`
- Reward deletion sets `wishlist_reward_id` to NULL (`on_delete: :nullify`) — kid simply loses goal, no cascading error
- Migration must be additive only (no destructive ops)

### Service layer
- New `Profiles::SetWishlistService` under `app/services/profiles/`
  - Inputs: `profile`, `reward` (or `nil` to clear)
  - Validates reward belongs to same family as profile (security boundary)
  - Wraps update in `ActiveRecord::Base.transaction`
  - Returns `ApplicationService::Result` with `data: { profile:, reward: }` on success
  - Broadcasts a Turbo Stream replace to `"kid_#{profile.id}"` channel updating the wishlist card
- `Rewards::RedeemService` augmented to clear `wishlist_reward_id` INSIDE the existing `@profile.lock!` transaction (between `decrement!` and `Redemption.create!`) when the redeemed reward IS the kid's pinned wishlist — must stay inside the same transaction for race safety
- **Wishlist card re-render strategy:** add an `after_update_commit :broadcast_wishlist_card` callback on `Profile` that fires when EITHER `points` OR `wishlist_reward_id` change. This consolidates re-render triggers into one place and removes the need to touch `Tasks::ApproveService` or duplicate broadcasts in `SetWishlistService`. The callback is responsible for the Turbo Stream replace; services just mutate state.
- Augment `Rewards::RedeemService` ONLY for the auto-clear (still inside its transaction) — broadcast happens automatically via the model callback when the column changes
- Controllers never write `profile.wishlist_reward_id` directly — always go through service

### Routes & controllers
- New nested resource under kid namespace:
  - `POST   /kid/wishlist`   → `Kid::WishlistController#create` (params: `reward_id`)
  - `DELETE /kid/wishlist`   → `Kid::WishlistController#destroy`
- Controller is PIN-gated profile-scoped (`session[:profile_id]`) per existing `kid/` namespace conventions
- No parent-side controller — parents READ only via existing `parent/profiles#show`

### UI / ViewComponents
- New `Ui::WishlistGoal::Component` under `app/components/ui/wishlist_goal/`
  - Two states: **filled** (kid has pinned reward) and **empty** (no pin yet, CTA "Escolher meta" linking to rewards index)
  - Progress bar uses Duolingo green (`--brand-primary`) with 3D `0 4px 0` shadow per DESIGN.md
  - Filled state renders: reward icon, title, `points/cost` text, animated progress bar, star delta ("Faltam Nx⭐"), "Resgatar agora" button when `progress >= 100%`
  - Component lives inside a Turbo Frame (`turbo_frame_tag dom_id(profile, :wishlist)`) so service broadcasts can replace it
  - Honors `prefers-reduced-motion` (no progress bar fill animation when reduced motion requested)
- `kid/rewards#index` cards gain a "Definir como meta" / "Remover meta" toggle button (small icon button, top-right of each `Ui::RewardCard`)
- `kid/dashboard` slots `Ui::WishlistGoal` between balance chip and missions list
- `Ui::KidProgressCard` (rendered on `parent/dashboard#index`) adds a read-only "Meta atual" line showing each kid's pinned reward (or "Sem meta" empty state). NO `parent/profiles#show` route is added.

### Realtime
- Reuse existing `"kid_#{profile.id}"` Turbo Stream channel — kid layout already subscribes via `app/views/kid/shared/_fx_stage.html.erb`
- Single broadcast source: `Profile` model `after_update_commit :broadcast_wishlist_card` callback fires when `points` OR `wishlist_reward_id` change. Uses `Turbo::StreamsChannel.broadcast_replace_to "kid_#{id}", target: dom_id(self, :wishlist), partial: "kid/wishlist/goal", locals: { profile: self }` (mirroring the synchronous broadcast pattern from `Tasks::ApproveService#broadcast_celebration` and `Rewards::RedeemService#broadcast_celebration`). Wrap in `rescue StandardError => e; Rails.logger.warn(...); end` per existing pattern.
- Services do NOT broadcast directly — they mutate Profile, the model callback handles broadcast.

### Testing (RSpec)
- Model spec: `Profile#wishlist_reward` association, nullify-on-delete behavior, `broadcast_wishlist_card` callback fires on points or wishlist_reward_id change (extend existing `spec/models/profile_spec.rb`)
- Service specs: `Profiles::SetWishlistService` (happy path, cross-family rejection, clear case)
- Service spec update: `Rewards::RedeemService` clears wishlist when redeeming pinned reward
- Request specs: `Kid::WishlistController#create` and `#destroy`
- Component preview: `Ui::WishlistGoal::Component` filled and empty states
- System spec: kid pins reward → dashboard shows goal → parent approves task → progress updates via Turbo Stream

### Conventions
- Brazilian Portuguese for all user-facing copy ("Minha meta", "Faltam Nx⭐", "Resgatar agora", "Sem meta")
- Code, commits, comments in English
- No raw hex colors — only theme tokens from `app/assets/stylesheets/tailwind/theme.css`
- Component CSS colocated with component per existing `Ui::*` pattern

### Claude's Discretion
- Exact progress bar visual treatment (height, animation curve) — match DESIGN.md spirit
- Empty-state copy wording for parent view ("Ainda não escolheu uma meta" or similar)
- Whether to show "Resgatar agora" CTA inside the wishlist card or only highlight it (suggested: show button to keep flow tight)
- Decimal handling: `progress = [profile.points.to_f / reward.cost, 1.0].min` (cap at 100%, never overflow visual)
- Whether to allow kid to pin a reward they cannot yet afford from a category currently disabled (yes — that's the whole point of a goal)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project conventions
- `CLAUDE.md` — project rules (services pattern, dual UI, Turbo broadcasts, Brazilian Portuguese conversation)
- `DESIGN.md` — Duolingo design system (tokens, 3D shadows, components, motion, a11y)
- `TECHSPEC.md` — authoritative architecture reference

### Service layer pattern
- `app/services/application_service.rb` — `Result` data type, `ok` / `fail_with` helpers
- `app/services/rewards/redeem_service.rb` — closest analog (mutates points, broadcasts to `kid_#` channel)
- `app/services/tasks/approve_service.rb` — broadcasts balance update; will need wishlist card replace too

### Models
- `app/models/profile.rb` — Profile (`points` integer, role enum, family belongs_to)
- `app/models/reward.rb` — Reward (`cost`, `category`, `family` belongs_to)

### UI patterns to follow
- `app/components/ui/balance_chip/` — example of a card with token colors + 3D shadow
- `app/components/ui/mission_card/` — bouncy hover, Duolingo style
- `app/components/ui/card/` — base card component
- `app/views/kid/dashboard/index.html.erb` — slot insertion pattern
- `app/views/kid/rewards/index.html.erb` — kid rewards grid (where pin toggle lands)

</canonical_refs>

<specifics>
## Specific Ideas

- Use Turbo Frame `dom_id(profile, :wishlist)` so the same frame is the broadcast target everywhere
- Migration name: `AddWishlistRewardIdToProfiles`
- DB index on `wishlist_reward_id` (nullable, low cardinality is fine — used in joins for parent profile show)
- `SetWishlistService.call(profile:, reward:)` — keyword args, reward can be `nil` to clear
- Empty state CTA copy: "Escolha um prêmio como meta ⭐"
- Filled state title: "Minha meta"
- Star delta phrasing: "Faltam Nx⭐" / "Pronto pra resgatar! 🎉" when funded
- Pin toggle on reward card: small star outline icon when not pinned, filled star when pinned
- No animation on progress bar in tests (set `prefers-reduced-motion` or stub) to avoid flake

</specifics>

<deferred>
## Deferred Ideas

- Multiple wishlist slots / priority ranking
- Parent-curated wishlists (parent suggests goals)
- Sibling wishlist visibility
- "Goal reached" push notification / email
- Auto-redeem when funded
- Wishlist history (what kid saved toward in the past)
- Streak flame visualization (separate phase)

</deferred>

---

*Phase: 06-wishlist-goal-tracking*
*Context gathered: 2026-04-30 inline*
