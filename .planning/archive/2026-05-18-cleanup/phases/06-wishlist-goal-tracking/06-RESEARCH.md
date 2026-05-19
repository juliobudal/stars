# Phase 6: Wishlist & Goal Tracking - Research

**Researched:** 2026-04-30
**Domain:** Rails 8 service-object + ViewComponent + Turbo Streams (kid-side gamification UI)
**Confidence:** HIGH

## Summary

This phase grafts a single-pin "savings goal" mechanic onto the existing star-economy. The codebase already has every primitive needed: a per-kid Turbo Stream channel (`"kid_#{profile.id}"`), a celebration/notification subscription wired into the kid layout via `kid/shared/_fx_stage`, an `ApplicationService` Result type with `ok` / `fail_with` helpers, and a 3D Duolingo-style component library with colocated CSS. Nothing about the desired feature requires a new infrastructure pattern — the work is **additive**: one nullable FK, one new service, one new controller, one new ViewComponent, plus two surgical additions inside `Tasks::ApproveService` and `Rewards::RedeemService`.

The most consequential implementation detail is that **`Profile#broadcast_points` already auto-fires on any `points` change** via `after_update_commit :broadcast_points, if: :saved_change_to_points?` (profile.rb:42). That means the wishlist progress card MUST also live behind `turbo_stream_from "kid_#{current_profile.id}"` (already subscribed in `_fx_stage.html.erb`) and get re-broadcast from the same `after_update_commit` hook OR from the same place ApproveService/RedeemService already broadcast celebrations. Adding a second `after_update_commit` callback in `Profile` for the wishlist replacement is the cleanest option — it co-locates the "points-changed → wishlist-progress-changed" coupling next to the existing balance-chip broadcast, eliminating duplicate work in both services.

The CONTEXT.md decisions are coherent with current architecture. One CONTEXT.md statement needs verification: `Ui::WishlistGoal::Component` is described as a "Turbo Frame target" using `dom_id(profile, :wishlist)` — Turbo Frames and Turbo Stream broadcast targets are different mechanisms; both work, but the planner should pick one and stay consistent. Recommendation below: use `turbo_frame_tag dom_id(profile, :wishlist)` inside the component and have services call `Turbo::StreamsChannel.broadcast_replace_to "kid_#{id}", target: dom_id(profile, :wishlist), partial: "kid/wishlist/card", locals: {...}` — same pattern as the celebration broadcast, just `replace` instead of `append`.

**Primary recommendation:** Mirror the `Tasks::ApproveService#broadcast_celebration` pattern exactly (synchronous `Turbo::StreamsChannel.broadcast_replace_to`, rescued StandardError, no later/async). Use `after_update_commit` on `Profile` for the points-driven re-render so neither Approve nor Redeem need duplicate broadcast code. Place the Turbo Frame at `dom_id(current_profile, :wishlist)` — verified collision-free below.

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Data model**
- Add `wishlist_reward_id` (nullable foreign key) to `profiles` table referencing `rewards.id`
- `belongs_to :wishlist_reward, class_name: "Reward", optional: true` on `Profile`
- Reward deletion sets `wishlist_reward_id` to NULL (`on_delete: :nullify`) — kid simply loses goal, no cascading error
- Migration must be additive only (no destructive ops)

**Service layer**
- New `Profiles::SetWishlistService` under `app/services/profiles/`
  - Inputs: `profile`, `reward` (or `nil` to clear)
  - Validates reward belongs to same family as profile (security boundary)
  - Wraps update in `ActiveRecord::Base.transaction`
  - Returns `ApplicationService::Result` with `data: { profile:, reward: }` on success
  - Broadcasts a Turbo Stream replace to `"kid_#{profile.id}"` channel updating the wishlist card
- `Rewards::RedeemService` augmented to clear `wishlist_reward_id` when the redeemed reward IS the kid's pinned wishlist (same transaction)
- `Tasks::ApproveService` already broadcasts balance to `"kid_#{profile.id}"` — must additionally re-render the wishlist card so progress bar reflects the new balance
- Controllers never write `profile.wishlist_reward_id` directly — always go through service

**Routes & controllers**
- New nested resource under kid namespace:
  - `POST   /kid/wishlist`   → `Kid::WishlistController#create` (params: `reward_id`)
  - `DELETE /kid/wishlist`   → `Kid::WishlistController#destroy`
- Controller is PIN-gated profile-scoped (`session[:profile_id]`) per existing `kid/` namespace conventions
- No parent-side controller — parents READ only via existing `parent/profiles#show`

**UI / ViewComponents**
- New `Ui::WishlistGoal::Component` under `app/components/ui/wishlist_goal/`
  - Two states: **filled** (kid has pinned reward) and **empty** (no pin yet, CTA "Escolher meta" linking to rewards index)
  - Progress bar uses Duolingo green (`--brand-primary`) with 3D `0 4px 0` shadow per DESIGN.md
  - Filled state renders: reward icon, title, `points/cost` text, animated progress bar, star delta ("Faltam Nx⭐"), "Resgatar agora" button when `progress >= 100%`
  - Component lives inside a Turbo Frame (`turbo_frame_tag dom_id(profile, :wishlist)`) so service broadcasts can replace it
  - Honors `prefers-reduced-motion` (no progress bar fill animation when reduced motion requested)
- `kid/rewards#index` cards gain a "Definir como meta" / "Remover meta" toggle button (small icon button, top-right of each `Ui::RewardCard`)
- `kid/dashboard` slots `Ui::WishlistGoal` between balance chip and missions list
- `parent/profiles#show` adds a read-only "Meta atual" section showing each kid's pinned reward (or "Sem meta" empty state)

**Realtime**
- Reuse existing `"kid_#{profile.id}"` Turbo Stream channel
- Two new broadcast triggers from services:
  - `Profiles::SetWishlistService` → replace wishlist Turbo Frame
  - Any service that mutates `profile.points` (`Tasks::ApproveService`, `Rewards::RedeemService`) → replace wishlist Turbo Frame so progress bar advances live

**Testing (RSpec)**
- Model spec: `Profile#wishlist_reward` association, nullify-on-delete behavior
- Service specs: `Profiles::SetWishlistService` (happy path, cross-family rejection, clear case)
- Service spec update: `Rewards::RedeemService` clears wishlist when redeeming pinned reward
- Request specs: `Kid::WishlistController#create` and `#destroy`
- Component preview: `Ui::WishlistGoal::Component` filled and empty states
- System spec: kid pins reward → dashboard shows goal → parent approves task → progress updates via Turbo Stream

**Conventions**
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

### Deferred Ideas (OUT OF SCOPE)
- Multiple wishlist slots / priority ranking
- Parent-curated wishlists (parent suggests goals)
- Sibling wishlist visibility
- "Goal reached" push notification / email
- Auto-redeem when funded
- Wishlist history (what kid saved toward in the past)
- Streak flame visualization (separate phase)

## Project Constraints (from CLAUDE.md)

| # | Directive | How it constrains this phase |
|---|-----------|------------------------------|
| C-1 | All business logic via services inheriting `ApplicationService`; controllers must not mutate state directly | `Kid::WishlistController` MUST delegate to `Profiles::SetWishlistService.call(...)`; never call `profile.update(wishlist_reward_id:...)` from the controller |
| C-2 | All services wrap multi-step mutations in `ActiveRecord::Base.transaction`; return `ApplicationService::Result` via `ok(data)` / `fail_with(error)` | `Profiles::SetWishlistService` MUST follow this exact pattern even though the mutation is a single `update!` (consistency + future-proof for multi-step changes like clearing-then-setting) |
| C-3 | Never allow negative `Profile.points`; use transactions with `reload` checks for race conditions | Wishlist add/remove does not touch points, but the `Rewards::RedeemService` augmentation runs INSIDE the existing `lock!` + transaction — the `wishlist_reward_id = nil` mutation is safe to add to the same `ActiveRecord::Base.transaction` block (lines 16-48 of redeem_service.rb) |
| C-4 | Brazilian Portuguese for user-facing copy, English for code/commits | All component literals (`"Minha meta"`, `"Faltam Nx⭐"`, `"Sem meta"`, `"Definir como meta"`) in pt-BR; class names, method names, log lines in English |
| C-5 | Reach for `Ui::*` ViewComponents first; only inline markup if no component fits, then add row to DESIGN.md §6 | Adding `Ui::WishlistGoal` requires updating `DESIGN.md` §6 in the same PR (component table around line 149-167) |
| C-6 | Raw hex colors forbidden outside `tailwind/theme.css` | Progress bar fill, "Resgatar agora" CTA, empty-state border MUST use `var(--primary)`, `var(--primary-2)`, `var(--primary-soft)`, `var(--star)`, `var(--hairline)` etc. — never hex |
| C-7 | Any element with `0 4px 0` depth shadow MUST honor 3D motion contract + `prefers-reduced-motion` | The wishlist card AND the "Resgatar agora" CTA AND the pin-toggle button use `ls-card-3d` / `ls-btn-3d` classes (already defined in `theme.css`) — those provide both the press + reduced-motion behavior for free |
| C-8 | Don't reintroduce retired tokens: Fraunces, lilac `#A78BFA`, Berry Pop / Soft Candy shadows | Wishlist UI uses Nunito (already body default) and Duolingo green/amber palette — no restoration risk |
| C-9 | Run tests via `make rspec` (Docker), never `bundle exec rspec` from host | Plan task acceptance steps must read "run `make rspec`" not "run `bundle exec rspec`" |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| `wishlist_reward_id` storage | Database / Storage | — | Single FK column on `profiles` — additive migration |
| Set/clear wishlist (write) | API / Backend (`Profiles::SetWishlistService`) | — | Service object per CLAUDE.md C-1; controller is a thin shim |
| Auto-clear on redeem | API / Backend (`Rewards::RedeemService` augmentation) | Database (transaction boundary) | Must run inside the existing `lock!` + transaction so concurrent redeems can't bypass it |
| Wishlist progress computation | API / Backend (component-level Ruby) | — | `[profile.points.to_f / reward.cost, 1.0].min` is a pure ratio — compute in `Ui::WishlistGoal::Component` from passed-in `profile` |
| Live progress updates | API → WebSocket (Turbo Streams via Solid Cable in prod, Async in dev) | Browser (Turbo handles DOM swap) | Same `"kid_#{profile.id}"` channel kid layout already subscribes to |
| Wishlist card render | API / Backend (ViewComponent) | Browser (CSS press effect) | Server-rendered per Rails Way; `ls-card-3d` provides client-side feedback |
| Pin / unpin toggle UI | Browser (button click) → API (form POST/DELETE) | — | `button_to redeem_kid_reward_path` style — no Stimulus controller needed unless optimistic UI is desired |
| Parent visibility | API / Backend (added to `Parent::DashboardController#index` or `KidProgressCard`) | — | Read-only; preload with `includes(:wishlist_reward)` to avoid N+1 |

## Phase Requirements

No requirement IDs were assigned to this phase. Functional scope is sourced from the ROADMAP.md Phase 6 entry and the CONTEXT.md `<domain>` section. The planner should derive task-level acceptance criteria directly from those CONTEXT.md decisions.

## Standard Stack

### Core (already in Gemfile.lock — verified versions)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `rails` | 8.1.3 | Framework | Project baseline |
| `turbo-rails` | 2.0.23 | Turbo Streams + Frames for live updates | Already wired (kid `_fx_stage` subscribes) |
| `view_component` | 4.7.0 | `Ui::WishlistGoal::Component` | All other `Ui::*` use this exact version |
| `solid_cable` | 3.0.12 | Production cable adapter (dev uses async) | Already in `cable.yml` — broadcasts work end-to-end |
| `stimulus-rails` | 1.3.4 | (only if optimistic-UI on toggle) | Auto-registered via `stimulus-vite-helpers` |
| `propshaft` | 1.3.2 | Asset pipeline | No changes needed |
| `rspec-rails` | 8.0.4 | Tests | Project standard |
| `factory_bot_rails` | 6.5.1 | Factories | Profile/Reward factories already present |
| `capybara` | 3.40.0 | System spec | Used by `reward_redemption_flow_spec.rb` |
| `standard` | 1.54.0 | Lint | `make lint` |

[VERIFIED: /home/julio-budal/Projetos/guardian/Gemfile.lock]

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `bcrypt` | (already present) | Profile PIN | Not needed for this phase, but lock-step with `Authenticatable` concern |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Per-`Profile` `after_update_commit` for wishlist re-render | Inline broadcast inside both `ApproveService` and `RedeemService` | Inline = duplicate code in two services + risk of drift if a third points-mutating service is added later. `after_update_commit` couples the broadcast to the actual data change (single source of truth). **Recommended: callback.** |
| `broadcast_replace_to` (synchronous) | `broadcast_replace_later_to` (job-queued) | The existing `ApproveService#broadcast_celebration` and `RedeemService#broadcast_celebration` BOTH use synchronous `Turbo::StreamsChannel.broadcast_append_to` (verified: tasks/approve_service.rb:83, rewards/redeem_service.rb:74). Stay consistent. The `_later_to` form requires Solid Queue and adds latency the kid will perceive as lag. **Recommended: synchronous.** |
| `Profile#broadcast_points` (existing pattern, model-callback driven) | Component-level rendering via `turbo_frame_tag` only | Existing `broadcast_points` already uses `Turbo::Broadcastable` model methods (`broadcast_update_to self, "notifications", target: ...`). The wishlist follows the SAME pattern but to the SAME stream as celebrations (`"kid_#{id}"`). Two stream subscriptions are already active in `_fx_stage`; no new subscription needed. |

**Installation:** None. All gems already in Gemfile.lock.

## Architecture Patterns

### System Architecture Diagram

```
                  ┌────────────────────────────┐
                  │  Kid browser (kid layout)   │
                  │  Subscribes (already):      │
                  │   - "kid_#{profile.id}"     │
                  │   - profile :notifications  │
                  └────────────┬───────────────┘
                               │ Turbo Stream WS
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                     Rails app                               │
│                                                             │
│  ┌─ Kid::WishlistController ─┐         ┌─ Kid::Rewards ─┐  │
│  │  POST   /kid/wishlist     │         │  POST  redeem  │  │
│  │  DELETE /kid/wishlist     │         └────────┬───────┘  │
│  └────────────┬──────────────┘                  │          │
│               │                                 │          │
│               ▼                                 ▼          │
│  ┌─ Profiles::SetWishlistService ─┐  ┌─ Rewards::Redeem ─┐ │
│  │  validate cross-family         │  │  +clear wishlist  │ │
│  │  txn { profile.update! }       │  │   if redeemed==pin│ │
│  │  broadcast_replace_to          │  │  (same txn)       │ │
│  └────────────┬───────────────────┘  └────────┬──────────┘ │
│               │                               │            │
│               ▼                               │            │
│  ┌─ Profile#after_update_commit ─┐            │            │
│  │   :saved_change_to_points?    │◄───────────┘            │
│  │   → broadcast_wishlist_card   │  (Tasks::Approve also   │
│  │   → broadcast_points (existing)│   triggers via points  │
│  └────────────┬───────────────────┘   change)              │
│               │                                            │
│               ▼                                            │
│  Turbo::StreamsChannel.broadcast_replace_to                │
│   "kid_#{id}", target: dom_id(profile, :wishlist),         │
│   partial: "kid/wishlist/card", locals: {profile:}         │
└──────────────────────────────┬─────────────────────────────┘
                               │
                               ▼
              Solid Cable (prod) / Async (dev)
                               │
                               ▼
           Browser swaps <turbo-frame id="profile_X_wishlist">
```

### Component Responsibilities

| File (new) | Responsibility |
|------------|----------------|
| `db/migrate/YYYYMMDDHHMMSS_add_wishlist_reward_id_to_profiles.rb` | Add nullable FK with `on_delete: :nullify` + index |
| `app/services/profiles/set_wishlist_service.rb` | Validate cross-family + wrap `profile.update!` in transaction + broadcast replace |
| `app/controllers/kid/wishlist_controller.rb` | PIN-gated; `before_action :require_child!`; thin shim to service |
| `app/components/ui/wishlist_goal/component.rb` | Initialize with `profile:`; expose `pinned?`, `progress_pct`, `stars_remaining`, `funded?` |
| `app/components/ui/wishlist_goal/component.html.erb` | Filled + empty branches; wrap in `<%= turbo_frame_tag dom_id(@profile, :wishlist) do %>` |
| `app/components/ui/wishlist_goal/component.css` | Colocated CSS for progress bar fill animation; `@media (prefers-reduced-motion: reduce)` block |
| `app/views/kid/wishlist/_card.html.erb` | Partial wrapper rendering `Ui::WishlistGoal::Component.new(profile:)` — used as broadcast partial |
| `config/routes.rb` (modified) | Add `resource :wishlist, only: %i[create destroy], controller: "wishlist"` inside `namespace :kid` |
| `app/models/profile.rb` (modified) | `belongs_to :wishlist_reward, class_name: "Reward", optional: true`; add `after_update_commit :broadcast_wishlist_card, if: :saved_change_to_points?` (or chain inside existing `broadcast_points`) |
| `app/services/rewards/redeem_service.rb` (modified) | Inside the transaction (after `decrement!`), if `@profile.wishlist_reward_id == @reward.id`: `@profile.update!(wishlist_reward_id: nil)` |
| `app/views/kid/dashboard/index.html.erb` (modified) | Slot `<%= render Ui::WishlistGoal::Component.new(profile: current_profile) %>` between level card (line 87) and missions section heading (line 90) |
| `app/views/kid/rewards/_affordable.html.erb` + `_locked.html.erb` (modified) | Add pin-toggle icon button (`button_to kid_wishlist_path, method: :post/:delete`) |
| `app/components/ui/kid_progress_card/component.html.erb` (modified) OR `app/views/parent/dashboard/index.html.erb` (modified) | Render kid's wishlist read-only chip ("Meta: 🎁 LEGO Star Wars · 80/200⭐") |
| `app/assets/entrypoints/application.css` (modified) | Add `@import "../../components/ui/wishlist_goal/component.css";` |
| `DESIGN.md` (modified) | Add `Ui::WishlistGoal` row to §6 components table |

### Recommended Project Structure

```
app/
├── components/ui/wishlist_goal/
│   ├── component.rb               # initialize(profile:); helpers for progress
│   ├── component.html.erb         # filled + empty states inside turbo_frame_tag
│   └── component.css              # colocated, imported in entrypoints/application.css
├── controllers/kid/
│   └── wishlist_controller.rb     # PIN-gated, thin shim
├── services/profiles/
│   └── set_wishlist_service.rb    # < ApplicationService; ok / fail_with
└── views/kid/wishlist/
    └── _card.html.erb             # partial used by broadcast_replace_to
```

### Pattern 1: Service Object (`ApplicationService` subclass)

**What:** All business logic in a service returning a `Result = Data.define(:success, :error, :data)`.
**When to use:** Any state mutation; controllers only orchestrate.
**Example:**
```ruby
# Source: app/services/rewards/redeem_service.rb (mirror this exactly)
module Profiles
  class SetWishlistService < ApplicationService
    def initialize(profile:, reward:)
      @profile = profile
      @reward  = reward # may be nil to clear
    end

    def call
      Rails.logger.info("[Profiles::SetWishlistService] start profile_id=#{@profile.id} reward_id=#{@reward&.id}")

      if @reward && @reward.family_id != @profile.family_id
        Rails.logger.info("[Profiles::SetWishlistService] failure cross_family")
        return fail_with("Reward não pertence a esta família")
      end

      ActiveRecord::Base.transaction do
        @profile.update!(wishlist_reward: @reward)
      end

      broadcast_replace
      Rails.logger.info("[Profiles::SetWishlistService] success")
      ok({ profile: @profile, reward: @reward })
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Profiles::SetWishlistService] exception #{e.message}")
      fail_with(e.message)
    end

    private

    def broadcast_replace
      Turbo::StreamsChannel.broadcast_replace_to(
        "kid_#{@profile.id}",
        target: ActionView::RecordIdentifier.dom_id(@profile, :wishlist),
        partial: "kid/wishlist/card",
        locals: { profile: @profile }
      )
    rescue StandardError => e
      Rails.logger.warn("[Profiles::SetWishlistService] broadcast failed: #{e.message}")
    end
  end
end
```

[CITED: app/services/rewards/redeem_service.rb:16-83 (transaction + broadcast pattern), app/services/application_service.rb:1-12 (Result type)]

### Pattern 2: Turbo Stream broadcast from a service (synchronous, rescued)

**What:** After committing the transaction, push a Turbo Stream operation to the kid's per-profile channel.
**When to use:** Whenever a service mutates state the kid is currently looking at.
**Example:**
```ruby
# Source: app/services/tasks/approve_service.rb:73-91 — exact pattern to mirror
def broadcast_celebration(...)
  Turbo::StreamsChannel.broadcast_append_to(
    "kid_#{@profile.id}",
    target: "fx_stage",
    partial: "kid/shared/celebration",
    locals: { tier: tier, payload: payload }
  )
rescue StandardError => e
  Rails.logger.warn("[Tasks::ApproveService] broadcast failed ... error=#{e.message}")
end
```

For wishlist, swap `broadcast_append_to` → `broadcast_replace_to` and target `dom_id(@profile, :wishlist)` instead of `"fx_stage"`.

### Pattern 3: Model-driven re-render on data change

**What:** Use `after_update_commit` with a guard like `:saved_change_to_points?` to broadcast whenever the underlying field changes — regardless of which service caused the change.
**When to use:** When multiple services can mutate the same field and all need to trigger the same UI update.
**Example:**
```ruby
# Source: app/models/profile.rb:42, 71-99 — extend the existing broadcast_points hook
class Profile < ApplicationRecord
  after_update_commit :broadcast_points,         if: :saved_change_to_points?
  after_update_commit :broadcast_wishlist_card,  if: :saved_change_to_points?
  after_update_commit :broadcast_wishlist_card,  if: :saved_change_to_wishlist_reward_id?

  private

  def broadcast_wishlist_card
    Turbo::StreamsChannel.broadcast_replace_to(
      "kid_#{id}",
      target: ActionView::RecordIdentifier.dom_id(self, :wishlist),
      partial: "kid/wishlist/card",
      locals: { profile: self }
    )
  rescue StandardError => e
    Rails.logger.warn("[Profile##{id}] wishlist broadcast failed: #{e.message}")
  end
end
```

This eliminates the need to add broadcast code to `Tasks::ApproveService` AND `Rewards::RedeemService` separately — the Profile callback fires on any `points` change (which both services trigger via `increment!` / `decrement!`).

[CITED: app/models/profile.rb:42 — existing `after_update_commit :broadcast_points` pattern]

### Pattern 4: PIN-gated kid controller

**What:** Standard `Authenticatable` concern + `before_action :require_child!`.
**When to use:** Every controller under `Kid::*` namespace.
**Example:**
```ruby
# Source: app/controllers/kid/rewards_controller.rb:1-5 — exact preamble to copy
class Kid::WishlistController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout "kid"

  def create
    reward = Reward.where(family_id: current_profile.family_id).find(params[:reward_id])
    result = Profiles::SetWishlistService.call(profile: current_profile, reward: reward)
    if result.success?
      respond_to do |fmt|
        fmt.html { redirect_to kid_rewards_path, notice: "Meta atualizada!" }
        fmt.turbo_stream { head :ok } # broadcast already pushed re-render
      end
    else
      redirect_to kid_rewards_path, alert: result.error
    end
  end

  def destroy
    result = Profiles::SetWishlistService.call(profile: current_profile, reward: nil)
    if result.success?
      respond_to do |fmt|
        fmt.html { redirect_to kid_rewards_path, notice: "Meta removida." }
        fmt.turbo_stream { head :ok }
      end
    else
      redirect_to kid_rewards_path, alert: result.error
    end
  end
end
```

[CITED: app/controllers/kid/rewards_controller.rb:1-5, app/controllers/concerns/authenticatable.rb:42-46]

### Pattern 5: ViewComponent with colocated CSS

**What:** `app/components/ui/<name>/component.rb` + `component.html.erb` + `component.css`. Stylesheet imported in `app/assets/entrypoints/application.css`.
**When to use:** Every `Ui::*` component.
**Example:**
```ruby
# Source: app/components/ui/balance_chip/component.rb (call-style) and
#         app/components/ui/mission_card/component.rb (template-style — preferred for >20 lines of markup)
module Ui
  module WishlistGoal
    class Component < ApplicationComponent
      def initialize(profile:)
        super()
        @profile = profile
        @reward  = profile.wishlist_reward
      end

      attr_reader :profile, :reward

      def pinned?       = reward.present?
      def progress_pct  = pinned? ? [(profile.points.to_f / reward.cost * 100).round, 100].min : 0
      def stars_remaining = pinned? ? [reward.cost - profile.points, 0].max : 0
      def funded?       = pinned? && profile.points >= reward.cost
    end
  end
end
```

```erb
<%# component.html.erb %>
<%= turbo_frame_tag dom_id(@profile, :wishlist) do %>
  <% if pinned? %>
    <%# filled state with progress bar, "Faltam Nx⭐", "Resgatar agora" CTA when funded? %>
  <% else %>
    <%# empty state CTA "Escolha um prêmio como meta ⭐" linking to kid_rewards_path %>
  <% end %>
<% end %>
```

[CITED: app/components/ui/mission_card/, app/components/ui/balance_chip/, app/assets/entrypoints/application.css:24-36 (CSS import pattern)]

### Anti-Patterns to Avoid

- **Mutating `profile.wishlist_reward_id` directly from the controller** — violates CLAUDE.md C-1, breaks the broadcast contract since the service is what fires `Turbo::StreamsChannel.broadcast_replace_to`.
- **Using `broadcast_replace_later_to`** — adds Solid Queue latency. The existing services use synchronous `broadcast_append_to`/`broadcast_update_to`. Stay consistent.
- **Adding broadcast code to `Tasks::ApproveService` AND `Rewards::RedeemService`** when the `Profile` model callback can fire on `saved_change_to_points?` from a single place. Avoid duplication.
- **Skipping the cross-family check** in `Profiles::SetWishlistService` — without it, a kid could pin another family's reward by passing an arbitrary `reward_id`. The `Reward.where(family_id: ...)` scope in the controller is necessary but not sufficient (defense in depth: also check in the service).
- **Animating progress bar with raw CSS `transition` not honoring `prefers-reduced-motion`** — DESIGN.md §5 mandates the contract; existing `ls-card-3d` and `ls-btn-3d` utilities already include the media query. Use them, don't write new transitions.
- **Inline raw hex** — every color goes through a CSS variable from `theme.css`.
- **Using `belongs_to :wishlist_reward` without `optional: true`** — Rails 5+ defaults `belongs_to` to required; without `optional: true` the `null` FK will fail validation.
- **Dropping the `Family` join check on `wishlist_reward.family_id == profile.family_id`** in the service — even with FK + index, the service is the security boundary.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Live progress bar updates | Custom WebSocket / polling JS | `turbo_stream_from "kid_#{profile.id}"` (already subscribed in `_fx_stage`) + `Turbo::StreamsChannel.broadcast_replace_to` | Solid Cable + Turbo handle reconnect, replay, idempotency. Already wired. |
| Service result type | Custom OpenStruct or raise/rescue chain | `ApplicationService::Result` (`ok(data)` / `fail_with(error)`) | Single canonical pattern across the app; already covered by every service spec. |
| 3D press animation | Raw CSS `transition` rules | `ls-card-3d`, `ls-btn-3d` utility classes from `theme.css` | They already include the `prefers-reduced-motion` carve-out. |
| Cross-family security check | Custom `RewardScope` query object | Inline `family_id != profile.family_id` guard in service + `current_profile.family.rewards` scoping in controller | Two-layer check is enough; the codebase doesn't have a query object pattern. |
| Turbo Frame DOM id generation | Manual `"profile_#{id}_wishlist"` strings | `ActionView::RecordIdentifier.dom_id(@profile, :wishlist)` | Standard Rails helper; auto-pluralized as `profile_#{id}_wishlist`. Verified collision-free below. |
| Per-kid Turbo Stream subscription | New `<turbo-cable-stream-source>` tag in dashboard | Reuse `_fx_stage` subscription already rendered in `kid.html.erb` layout | Don't double-subscribe; the layout already handles it for celebrations. |
| Pin-toggle button | Stimulus controller with optimistic UI | Plain `button_to kid_wishlist_path, method: :post` (form auto-Turbo-submits) | The broadcast back round-trips fast enough on the kid's same-network link. Optimistic UI is YAGNI for v1. |

**Key insight:** Almost every primitive needed by this phase is already in the codebase — the work is mostly composition. The single place where a beginner might over-engineer is the broadcast wiring; the answer is "let `Profile`'s `after_update_commit` do it."

## Common Pitfalls

### Pitfall 1: `belongs_to :wishlist_reward` without `optional: true`
**What goes wrong:** Validation error "Wishlist reward must exist" on every `Profile.update` (or every `Profile.create`).
**Why it happens:** Rails 5+ `belongs_to` defaults to required.
**How to avoid:** Always include `optional: true` for nullable FKs; the existing `belongs_to :global_task, optional: true` in `app/models/profile_task.rb:37` is the canonical example.
**Warning signs:** Test failures like `Validation failed: Wishlist reward must exist` even when nothing about wishlist was touched.

### Pitfall 2: `dom_id(profile, :wishlist)` collision with another stream target
**What goes wrong:** Broadcast updates the wrong DOM node.
**Why it happens:** Two different partials use the same identifier.
**How to avoid:** Verified — `dom_id(profile, :wishlist)` produces `"profile_#{id}_wishlist"`. Grepped the codebase for `_wishlist`, `profile_.*_wishlist`, and `dom_id(.*profile.*wishlist)` — **no collisions exist**. The only `dom_id`-keyed broadcast targets currently in use are `"profile_points_#{id}"` (balance chip), `dom_id(task)` (mission card), `dom_id(reward)` (reward modal), `"fx_stage"` (celebration), and `"approvals_list"` / `"panel-rewards"` (parent). Safe to add `profile_X_wishlist`.
**Warning signs:** Live updates clobber unrelated UI.

### Pitfall 3: Forgetting `prefers-reduced-motion` on the progress bar fill animation
**What goes wrong:** Vestibular accessibility regression. DESIGN.md §5 mandates the carve-out; `make ci` doesn't catch this automatically.
**Why it happens:** A new component author writes a fresh `transition: width 0.5s` rule.
**How to avoid:** Either (a) use `transition` only inside an `@media (prefers-reduced-motion: no-preference) { ... }` block, OR (b) wrap the fill bar in an existing utility class. Pattern from `kid/dashboard/index.html.erb:71` — the level progress bar uses `transition-all duration-500` Tailwind class without a guard, so this is actually a project-wide gap; recommend adding the guard in the new component to set a positive precedent.
**Warning signs:** No automated check — code review catches it. Add a comment in the component CSS marking the reduced-motion carve-out.

### Pitfall 4: Forgetting to clear wishlist when redeeming the pinned reward INSIDE the transaction
**What goes wrong:** Redeem succeeds, kid keeps a wishlist pointing to a reward they no longer want (or worse, the next time they earn enough points the funded CTA reappears for an already-redeemed reward — confusing UX).
**Why it happens:** The auto-clear is added as an `after_commit` hook outside the transaction or as a separate service call, breaking atomicity. If the post-redeem clear fails, the points are already gone.
**How to avoid:** Add the `@profile.update!(wishlist_reward_id: nil) if @profile.wishlist_reward_id == @reward.id` inline in `Rewards::RedeemService#call`, BETWEEN the existing `@profile.decrement!` (line 33) and the `Redemption.create!` (line 35). Same transaction, same `lock!`. If the clear raises, the entire redeem rolls back.
**Warning signs:** Wishlist persists after redeem; `redeem_service_spec.rb` should add a test: "clears wishlist when redeeming the pinned reward".

### Pitfall 5: N+1 on parent profile show (or dashboard) listing kids' wishlists
**What goes wrong:** Each `Ui::KidProgressCard` calls `child.wishlist_reward` which fires a separate query per kid.
**Why it happens:** `current_family.profiles.child` doesn't include the new association.
**How to avoid:** Update the controller queries: `@children = @family.profiles.child.includes(:wishlist_reward)`. Verify with `bullet` if it's installed; otherwise eyeball the dev log.
**Warning signs:** Dev log shows N queries `SELECT * FROM rewards WHERE id = ?` on parent dashboard load.

### Pitfall 6: Broadcasting before the transaction commits
**What goes wrong:** The kid's UI replaces the wishlist card with stale data because the broadcast fires before the DB row update is visible to subsequent queries (or, worse, the transaction rolls back after the broadcast fired and the UI never corrects).
**Why it happens:** Calling `Turbo::StreamsChannel.broadcast_replace_to` INSIDE `ActiveRecord::Base.transaction { ... }` block.
**How to avoid:** Always broadcast AFTER the `transaction do ... end` block closes. Pattern verified: `Tasks::ApproveService` lines 30-51 transaction → line 54 broadcast_celebration; `Rewards::RedeemService` lines 16-48 transaction → line 56 broadcast_celebration.
**Warning signs:** Race-condition flake in system specs; sporadic stale UI.

### Pitfall 7: Async cable adapter in test environment swallows broadcasts
**What goes wrong:** `have_broadcasted_to` matcher works in dev but fails in CI.
**Why it happens:** `config/cable.yml` test adapter is `test`, which captures broadcasts for the matcher. `async` (used in dev) does not. **This is correct config** — but the test file must require the right helper. Verified: `redeem_service_spec.rb` uses `have_broadcasted_to` successfully (line 33-40) — pattern is solid. Just mirror it.
**Warning signs:** "expected stream to have been broadcasted to but it wasn't" only in CI.

## Runtime State Inventory

This phase is greenfield (additive: one column, one service, one controller, one component). It does NOT rename, refactor, migrate data, or change existing strings. Section omitted per researcher guidance.

## Code Examples

### Migration

```ruby
# Source pattern: db/migrate/20260423213717_create_profile_invitations.rb:7-15
#                 db/migrate/20260426233731_add_custom_mission_fields_to_profile_tasks.rb:9-11
class AddWishlistRewardIdToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_reference :profiles, :wishlist_reward,
                  foreign_key: { to_table: :rewards, on_delete: :nullify },
                  null: true,
                  index: true
  end
end
```

[CITED: db/migrate/20260423213717_create_profile_invitations.rb (foreign_key + on_delete syntax), db/migrate/20260426233731_add_custom_mission_fields_to_profile_tasks.rb (add_reference with foreign_key hash)]

### Service spec scaffold

```ruby
# Source pattern: spec/services/rewards/redeem_service_spec.rb (full file shape + helpers)
require 'rails_helper'

RSpec.describe Profiles::SetWishlistService do
  let(:family) { create(:family) }
  let(:other_family) { create(:family) }
  let(:child)  { create(:profile, :child, family: family, points: 30) }
  let(:reward) { create(:reward, family: family, cost: 100) }
  let(:foreign_reward) { create(:reward, family: other_family, cost: 100) }

  describe '#call' do
    context 'pinning a same-family reward' do
      it 'sets wishlist_reward on the profile' do
        result = described_class.call(profile: child, reward: reward)
        expect(result.success?).to be true
        expect(child.reload.wishlist_reward).to eq(reward)
      end

      it 'broadcasts a Turbo Stream replace to the kid channel' do
        expect {
          described_class.call(profile: child, reward: reward)
        }.to have_broadcasted_to("kid_#{child.id}")
          .from_channel(Turbo::StreamsChannel)
      end
    end

    context 'pinning a cross-family reward' do
      it 'returns failure and does not change the profile' do
        result = described_class.call(profile: child, reward: foreign_reward)
        expect(result.success?).to be false
        expect(result.error).to match(/família/i)
        expect(child.reload.wishlist_reward).to be_nil
      end
    end

    context 'clearing (reward: nil)' do
      before { child.update!(wishlist_reward: reward) }

      it 'sets wishlist_reward to nil' do
        result = described_class.call(profile: child, reward: nil)
        expect(result.success?).to be true
        expect(child.reload.wishlist_reward).to be_nil
      end
    end
  end
end
```

### Updated `Rewards::RedeemService` patch (illustrative diff)

```ruby
# Inside ActiveRecord::Base.transaction block — between decrement! and Redemption.create!
@profile.decrement!(:points, @reward.cost)

# NEW: auto-clear wishlist if redeeming the pinned reward
if @profile.wishlist_reward_id == @reward.id
  @profile.update!(wishlist_reward_id: nil)
end

redemption = Redemption.create!(...)
```

### Updated `Profile` model (illustrative diff)

```ruby
class Profile < ApplicationRecord
  belongs_to :family
  belongs_to :wishlist_reward, class_name: "Reward", optional: true  # NEW
  # ... existing has_many ...

  after_update_commit :broadcast_points,        if: :saved_change_to_points?
  after_update_commit :broadcast_wishlist_card, if: -> { saved_change_to_points? || saved_change_to_wishlist_reward_id? }  # NEW

  # ... existing methods ...

  private

  def broadcast_wishlist_card
    Turbo::StreamsChannel.broadcast_replace_to(
      "kid_#{id}",
      target: ActionView::RecordIdentifier.dom_id(self, :wishlist),
      partial: "kid/wishlist/card",
      locals: { profile: self }
    )
  rescue StandardError => e
    Rails.logger.warn("[Profile##{id}] wishlist broadcast failed: #{e.message}")
  end
end
```

### System spec scaffold

```ruby
# Source pattern: spec/system/reward_redemption_flow_spec.rb (PIN-gated dual session)
require "rails_helper"

RSpec.describe "Wishlist Goal Flow", type: :system do
  let!(:family) { create(:family, name: "Teste") }
  let!(:parent) { create(:profile, :parent, family: family, name: "Papai") }
  let!(:child)  { create(:profile, :child, family: family, name: "Filhote", points: 50) }
  let!(:reward) { create(:reward, family: family, title: "LEGO", cost: 100) }

  it "kid pins a reward and dashboard reflects the goal with progress" do
    sign_in_as_child(child)
    visit kid_rewards_path

    # Pin via the new toggle button (find by accessible name, not class)
    within("[data-reward-id='#{reward.id}']") do
      click_on "Definir como meta"
    end

    visit kid_root_path
    expect(page).to have_content("Minha meta")
    expect(page).to have_content("LEGO")
    expect(page).to have_content("Faltam 50") # 100 - 50
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `OpenStruct.new(success?: true)` (TECHSPEC.md §5 example, lines 314-315) | `ApplicationService::Result = Data.define(:success, :error, :data)` | Pre-Phase-6 (already in `app/services/application_service.rb`) | All new services MUST inherit `ApplicationService` and call `ok(data)` / `fail_with(error)`. The TECHSPEC examples are stale; do not copy them. |
| Manual `success` / `failure` private helpers | `ok(data)` / `fail_with(error)` from `ApplicationService` | Same | Idiomatic; supported by every existing test using `result.success?`. |
| `Turbo::StreamsChannel.broadcast_update_to` (TECHSPEC.md §8 example) | `Turbo::StreamsChannel.broadcast_replace_to` for full element swap; `broadcast_append_to` for transient stage (e.g. fx_stage celebrations); `broadcast_update_to` only when replacing inner HTML of a stable wrapper (Profile#broadcast_points uses this) | Wishlist needs `replace_to` because the entire frame's contents change (filled ↔ empty states differ structurally) | Use `replace_to` not `update_to` for the wishlist card. |

**Deprecated/outdated:**
- `OpenStruct`-based service results — superseded by `ApplicationService::Result`.
- `bin/rails server` directly — use `make dev` (Docker).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Rails 8.1 | Migration, models, controllers | ✓ | 8.1.3 | — |
| PostgreSQL 16+ | FK + index | ✓ (in Compose) | per docker-compose | — |
| Solid Cable | Production Turbo Streams | ✓ | 3.0.12 | Async adapter (dev) — already configured |
| Turbo (turbo-rails) | Streams + Frames | ✓ | 2.0.23 | — |
| ViewComponent | `Ui::WishlistGoal` | ✓ | 4.7.0 | — |
| RSpec + FactoryBot + Capybara | Tests | ✓ | 8.0.4 / 6.5.1 / 3.40.0 | — |

**No missing dependencies.** All tools needed by this phase are already in `Gemfile.lock` and Docker Compose.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | RSpec 8.0.4 (`rspec-rails`) + FactoryBot 6.5.1 + Capybara 3.40.0 |
| Config file | `spec/rails_helper.rb`, `spec/spec_helper.rb`, `.rspec` |
| Quick run command | `make rspec SPEC=spec/services/profiles/set_wishlist_service_spec.rb` (or `make shell` then `bundle exec rspec spec/services/profiles/set_wishlist_service_spec.rb:LINE`) |
| Full suite command | `make rspec` (alias `make test`) |

⚠️ **Project rule (from CLAUDE.md):** Always run via `make rspec` inside the `web` Docker container. `bundle exec rspec` from the host fails because the `db` host is unreachable. Plan task acceptance MUST specify `make rspec`.

### Phase Requirements → Test Map

| Behavior | Test Type | Automated Command | File Exists? |
|----------|-----------|-------------------|--------------|
| `Profile#wishlist_reward` association + nullify-on-delete | model | `make rspec SPEC=spec/models/profile_spec.rb` | ❌ Wave 0: create `spec/models/profile_spec.rb` (none exists today) |
| `Profiles::SetWishlistService` happy + cross-family + clear | service | `make rspec SPEC=spec/services/profiles/set_wishlist_service_spec.rb` | ❌ Wave 0: create `spec/services/profiles/` directory + spec |
| `Rewards::RedeemService` clears wishlist when redeeming pinned reward | service (extension) | `make rspec SPEC=spec/services/rewards/redeem_service_spec.rb` | ✅ Extend existing file |
| `Tasks::ApproveService` triggers wishlist re-render via points change | service (extension) | `make rspec SPEC=spec/services/tasks/approve_service_spec.rb` | ✅ Extend existing file (add `have_broadcasted_to "kid_#{child.id}"` assertion that includes wishlist target) |
| `Kid::WishlistController#create` and `#destroy` | request | `make rspec SPEC=spec/requests/kid/wishlist_controller_spec.rb` | ❌ Wave 0: create file under `spec/requests/kid/` |
| `Ui::WishlistGoal::Component` filled + empty preview | component | `make rspec SPEC=spec/components/ui/wishlist_goal/component_spec.rb` | ❌ Wave 0: create file |
| End-to-end pin → dashboard → approve → progress updates | system | `make rspec SPEC=spec/system/wishlist_flow_spec.rb` | ❌ Wave 0: create file |

### Sampling Rate
- **Per task commit:** Quick run of the spec being written (`make rspec SPEC=...`)
- **Per wave merge:** All Phase 6 specs (services + components + requests + system)
- **Phase gate:** Full suite green (`make rspec`) before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `spec/services/profiles/set_wishlist_service_spec.rb` — service spec scaffold
- [ ] `spec/models/profile_spec.rb` — does not exist; create for `wishlist_reward` association tests (low-effort but missing)
- [ ] `spec/requests/kid/wishlist_controller_spec.rb`
- [ ] `spec/components/ui/wishlist_goal/component_spec.rb`
- [ ] `spec/system/wishlist_flow_spec.rb`
- [ ] No new framework install required — RSpec + FactoryBot + Capybara already configured.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes (existing) | `Authenticatable` concern (family password + profile PIN); no changes needed |
| V3 Session Management | yes (existing) | Rails session + `cookies.signed[:family_id]`; no changes needed |
| V4 Access Control | **yes — critical for this phase** | `before_action :require_child!` on `Kid::WishlistController`; `Reward.where(family_id: current_profile.family_id).find(params[:reward_id])` to scope IDs to family; cross-family check in `Profiles::SetWishlistService` (defense in depth) |
| V5 Input Validation | yes | Rails strong-params on `params[:reward_id]` (integer cast); `find(...)` raises `RecordNotFound` (handled by `ApplicationController#not_found`) for invalid IDs |
| V6 Cryptography | no | No cryptographic operations in this phase |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| **IDOR — pin another family's reward** | Tampering / Information Disclosure | Two-layer check: (1) controller scopes `Reward.where(family_id: current_profile.family_id).find(...)` so a foreign `reward_id` raises 404; (2) service re-validates `reward.family_id != profile.family_id` and returns `fail_with("Reward não pertence a esta família")`. Mirrors the existing pattern in `app/controllers/kid/rewards_controller.rb:22` |
| **Privilege escalation — kid sets another kid's wishlist** | Elevation of Privilege | The controller only ever passes `current_profile` (the PIN-authenticated session) to the service. There is no `:profile_id` param accepted. |
| **CSRF on POST/DELETE** | Tampering | Rails default `protect_from_forgery with: :exception` (in `ApplicationController:5`) plus `button_to` form helpers include the authenticity token. No `skip_forgery_protection` needed. |
| **Mass assignment** | Tampering | The new column `wishlist_reward_id` is NEVER added to a strong-params permit list (no form field on a Profile form sets it) — only the service touches it via `update!(wishlist_reward: ...)`. |
| **Foreign key integrity** | Tampering | DB-level FK constraint with `on_delete: :nullify` ensures referential integrity even if a parent deletes a reward outside the wishlist UI. |

## Sources

### Primary (HIGH confidence)
- **Codebase grep + read** (entire research session): all version numbers from `Gemfile.lock`; all patterns from actual files cited inline
- `app/services/rewards/redeem_service.rb` — service shape, transaction, broadcast pattern
- `app/services/tasks/approve_service.rb` — service shape, broadcast pattern, Streaks integration to NOT touch
- `app/services/application_service.rb` — `Result` data type contract
- `app/models/profile.rb` — existing `after_update_commit :broadcast_points` callback (the hook to extend)
- `app/views/kid/shared/_fx_stage.html.erb` — confirms `turbo_stream_from "kid_#{current_profile.id}"` is already subscribed in the kid layout
- `app/controllers/concerns/authenticatable.rb` — `require_child!`, `current_profile` semantics
- `db/migrate/20260423213717_create_profile_invitations.rb` and `20260426233731_add_custom_mission_fields_to_profile_tasks.rb` — proven `foreign_key: { on_delete: :nullify }` migration syntax for Rails 8.1
- `spec/services/rewards/redeem_service_spec.rb` — exact `have_broadcasted_to` matcher pattern + `Turbo::StreamsChannel` channel reference
- `spec/system/reward_redemption_flow_spec.rb` — PIN-gated kid + parent dual-session system spec pattern
- `DESIGN.md` — Duolingo tokens, motion contract, component table location for §6 update
- `CLAUDE.md` — service pattern, Brazilian Portuguese rule, `make rspec` rule

### Secondary (MEDIUM confidence)
- None — this research relied entirely on the local codebase (HIGH confidence) since the patterns being replicated are project-specific.

### Tertiary (LOW confidence)
- None.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `parent/profiles#show` page mentioned in CONTEXT.md does not exist today (only `index`, `new`, `edit` actions are defined; `routes.rb:18-22` confirms `only: [:index, :new, :create, :edit, :update, :destroy]`). The closest parent-side surface for "kid wishlist visibility" is `parent/dashboard#index` rendering `Ui::KidProgressCard`. | Decisions / Component table | If a dedicated `show` action is intended, the planner needs to add a route + view + controller action — additional work not currently in any task list. **Recommend:** planner clarifies with user whether to (a) inject wishlist into the existing `Ui::KidProgressCard` on the parent dashboard, (b) add a new `show` action, or (c) add wishlist to `parent/profiles#edit`. |
| A2 | `dom_id(profile, :wishlist)` produces `"profile_<id>_wishlist"` with no collisions. Verified by grep — no existing target uses this string. | Pitfall 2 | Low. If a future phase introduces a colliding ID, this will surface as a clobbered DOM swap during dev — easy to detect and rename. |
| A3 | `Profile#after_update_commit :broadcast_wishlist_card, if: :saved_change_to_points?` is the right place to wire the points-change re-render (vs. duplicating in both `ApproveService` and `RedeemService`). | Pattern 3 / Architecture | Low. If the user prefers explicit broadcasts in services for traceability, the planner can move the broadcast into `Tasks::ApproveService#broadcast_celebration` and `Rewards::RedeemService#broadcast_celebration` blocks instead. The model-callback approach is **recommended** for less duplication and single-source coupling. |
| A4 | Solid Cable adapter + `test` adapter in test environment work correctly with the `have_broadcasted_to` matcher (mirroring `redeem_service_spec.rb` line 33-40 which uses this matcher and passes). | Validation Architecture | Very low — verified via existing passing spec. |
| A5 | The empty-state CTA "Escolha um prêmio como meta ⭐" routes to `kid_rewards_path` (the rewards index where the new pin toggle lives). | UI / claim's discretion | Low. If user wants a different destination (e.g. a curated "goal-worthy rewards" filter), planner should confirm. |
| A6 | Adding `after_update_commit :broadcast_wishlist_card, if: :saved_change_to_wishlist_reward_id?` is necessary in addition to the points hook so that pin/unpin operations done via `Profiles::SetWishlistService` trigger the same callback path the broadcast in the service triggers. **Could double-broadcast** — service emits one, callback emits another. | Code Examples / Pattern 3 | Medium. If both fire, the kid sees two near-instant DOM swaps. Two safe options: (a) drop the explicit broadcast in `Profiles::SetWishlistService` and rely on the model callback only (recommended — simpler), or (b) keep the service broadcast and remove the wishlist_reward_id condition from the callback. The planner should pick ONE and document it. |

## Open Questions

1. **Where does parent visibility actually live?**
   - What we know: CONTEXT.md says "parent profile show page" — but there's no `show` action on `Parent::ProfilesController` today.
   - What's unclear: Is the intent (a) a NEW `show` action + view, or (b) augment the existing `Ui::KidProgressCard` rendered on `parent/dashboard#index`, or (c) add to the kid management page (which is `parent/profiles#edit`)?
   - **Recommendation:** Augment `Ui::KidProgressCard` on `parent/dashboard#index` — minimal new surface area, kids' info is already aggregated there. If the planner / user prefers a dedicated show, a follow-up task adds the route + view.

2. **Service-broadcast vs. model-callback broadcast — pick one to avoid double-fire.**
   - What we know: `Profile#after_update_commit` can fire on both `points` change AND `wishlist_reward_id` change. `Profiles::SetWishlistService` also has its own `broadcast_replace`. Without coordination, pin/unpin fires twice.
   - What's unclear: Which is canonical?
   - **Recommendation (A6 above):** Drop the explicit broadcast in `Profiles::SetWishlistService` and rely on the `Profile#broadcast_wishlist_card` callback alone. Cleaner and idempotent.

3. **Pin toggle — Stimulus controller or pure form?**
   - What we know: `button_to` with `method: :post / :delete` works without JS and Turbo will use the Stream broadcast for the round-trip update.
   - What's unclear: Is optimistic UI desired (instant toggle, then reconcile)?
   - **Recommendation:** Plain `button_to` for v1. Optimistic UI is YAGNI; the Turbo round-trip on a same-network kid device is < 100ms.

4. **Should the "Resgatar agora" CTA in the wishlist card actually trigger redeem inline, or just link to the rewards index modal?**
   - What we know: CONTEXT.md says "show button to keep flow tight."
   - What's unclear: Tapping it should open the existing redeem-ritual modal (`#modal_<%= dom_id(reward) %>`) OR submit redeem directly?
   - **Recommendation:** Link/scroll to the existing modal on `kid_rewards_path` — keeps the established "Você quer trocar?" ritual and avoids duplicating the cost/aftermath UI. Anchor: `kid_rewards_path(anchor: dom_id(reward))` plus a small JS line in the existing `ui-modal#open` action — or just `link_to ... data: { ui_modal_id_param: "modal_#{dom_id(reward)}" }` if the modal HTML is rendered on the dashboard too. Simpler: link straight to the rewards index where the modal already exists.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions verified from `Gemfile.lock`
- Architecture: HIGH — every pattern cited from existing files in the codebase
- Pitfalls: HIGH — derived from observable code patterns (e.g. `belongs_to optional: true`, `lock!` + transaction, `prefers-reduced-motion` mandate in DESIGN.md)
- Security: HIGH — IDOR / cross-family check is a known concern in this app and the mitigation pattern is already established in `Kid::RewardsController`
- Open questions (especially Q1 about parent visibility surface): MEDIUM — needs user clarification before plan-finalize

**Research date:** 2026-04-30
**Valid until:** 2026-05-30 (30 days — stack is stable; only invalidated if Rails or Turbo majors are bumped)
