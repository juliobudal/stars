# Phase 6: Wishlist & Goal Tracking - Pattern Map

**Mapped:** 2026-04-30
**Files analyzed:** 21 (12 new + 9 modified)
**Analogs found:** 21 / 21 (every file has an in-repo analog)

> Important correction to upstream docs: `spec/models/profile_spec.rb` **already exists**
> (verified `ls spec/models/profile_spec.rb`). CONTEXT.md / RESEARCH.md called it new.
> The planner should **extend** the existing file, not create one. See "File Classification" below.

## File Classification

### NEW files

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `db/migrate/<TS>_add_wishlist_reward_id_to_profiles.rb` | migration | schema-additive | `db/migrate/20260426233731_add_custom_mission_fields_to_profile_tasks.rb` | exact (same `add_reference` + nullify FK shape) |
| `app/services/profiles/set_wishlist_service.rb` | service | request-response (CRUD-on-Profile) | `app/services/rewards/redeem_service.rb` | role-match (mutates Profile inside `transaction`, returns `Result`) |
| `app/controllers/kid/wishlist_controller.rb` | controller | request-response | `app/controllers/kid/rewards_controller.rb` | exact (kid-namespace, PIN-gated, thin shim to service) |
| `app/components/ui/wishlist_goal/component.rb` | component (ViewComponent) | render | `app/components/ui/kid_progress_card/component.rb` | exact (same shape: takes a model, exposes computed helpers, has progress bar) |
| `app/components/ui/wishlist_goal/component.html.erb` | component template | render | `app/components/ui/kid_progress_card/component.html.erb` | exact (progress bar markup + `ls-card-3d` shadow) |
| `app/components/ui/wishlist_goal/component.css` | component CSS (colocated) | static | `app/components/ui/pin_modal/component.css` | exact (same `prefers-reduced-motion` carve-out pattern) |
| `app/views/kid/wishlist/_goal.html.erb` | broadcast partial | render-from-broadcast | `app/views/kid/dashboard/_pending_card.html.erb` | role-match (kid-namespace partial wrapping a component render) |
| `spec/services/profiles/set_wishlist_service_spec.rb` | service spec | test | `spec/services/rewards/redeem_service_spec.rb` | exact (same `Result` assertions + `have_broadcasted_to`) |
| `spec/requests/kid/wishlist_controller_spec.rb` | request spec | test | `spec/requests/kid/wallet_and_rewards_spec.rb` | exact (same `sign_in_as` + `host! "localhost"`) |
| `spec/components/ui/wishlist_goal/component_spec.rb` | component spec | test | `spec/components/ui/kid_progress_card/component_spec.rb` | exact (same `render_inline` / `have_text` assertions) |
| `spec/system/kid_wishlist_spec.rb` | system spec | test | `spec/system/reward_redemption_flow_spec.rb` | exact (PIN-gated dual-session pattern) |

### MODIFIED files

| Modified File | Role | Data Flow | Closest Pattern Source | Match Quality |
|---------------|------|-----------|------------------------|---------------|
| `app/models/profile.rb` | model | event-driven (broadcast) | `app/models/profile.rb:42,71-99` (existing `broadcast_points` callback) | exact (same file — extend existing pattern) |
| `app/services/rewards/redeem_service.rb` | service | CRUD | `app/services/rewards/redeem_service.rb:16-48` (the `transaction` block to extend) | exact (extend existing transaction in place) |
| `app/views/kid/dashboard/index.html.erb` | view | render | self — slot pattern at line 87→90 boundary | exact (insert component render between two existing sections) |
| `app/views/kid/rewards/_affordable.html.erb` | partial | render | self — `data-controller="ui-modal"` overlay button pattern (line 14-22) | role-match (add a second action button on the card) |
| `app/views/kid/rewards/_locked.html.erb` | partial | render | self — same as `_affordable` | role-match |
| `app/components/ui/kid_progress_card/component.rb` + `.html.erb` | component | render | self (line 28-43 of template — text-row pattern for "X saldo / Y ativas") | role-match (add a "Meta atual" line in same flex row block) |
| `config/routes.rb` | config | static | `config/routes.rb:44-53` (existing `namespace :kid` block) | exact (add `resource :wishlist` line inside the same block) |
| `app/assets/entrypoints/application.css` | config | static | `app/assets/entrypoints/application.css:25-36` (existing `@import "../../components/ui/.../component.css"` lines) | exact (one new line following the pattern) |
| `spec/services/rewards/redeem_service_spec.rb` | service spec | test | self — append a new `context` block | exact (extend existing file) |

---

## Pattern Assignments

### `db/migrate/<TS>_add_wishlist_reward_id_to_profiles.rb` (migration)

**Analog:** `db/migrate/20260426233731_add_custom_mission_fields_to_profile_tasks.rb`

**Migration shape pattern** (lines 1-16):
```ruby
class AddCustomMissionFieldsToProfileTasks < ActiveRecord::Migration[8.1]
  def change
    change_column_null :profile_tasks, :global_task_id, true

    add_column :profile_tasks, :source,              :integer, default: 0, null: false
    # ...
    add_reference :profile_tasks, :custom_category,
                  foreign_key: { to_table: :categories, on_delete: :nullify },
                  null: true
    # ...
    add_index :profile_tasks, :source
  end
end
```

**`on_delete: :nullify` FK pattern** — re-usable from line 9-11 of the analog. `add_reference` already creates the index when `null: true` is passed; do **not** add a separate `add_index` for `wishlist_reward_id` (it would duplicate).

**Adaptation notes:**
- File header: `class AddWishlistRewardIdToProfiles < ActiveRecord::Migration[8.1]`
- Single op: `add_reference :profiles, :wishlist_reward, foreign_key: { to_table: :rewards, on_delete: :nullify }, null: true`
- Schema annotation will be regenerated automatically; do not hand-edit the `# == Schema Information` block in `app/models/profile.rb` — `annotate` rake task (or just `make migrate`) handles it.

---

### `app/services/profiles/set_wishlist_service.rb` (service, CRUD-on-Profile)

**Analog:** `app/services/rewards/redeem_service.rb`

**Imports / module shape pattern** (lines 1-11):
```ruby
module Rewards
  class RedeemService < ApplicationService
    def initialize(profile:, reward:)
      @profile = profile
      @reward = reward
    end

    def call
      Rails.logger.info(
        "[Rewards::RedeemService] start profile_id=#{@profile.id} reward_id=#{@reward.id} cost=#{@reward.cost}"
      )
```

**Transaction + result pattern** (lines 16-61) — the canonical `ApplicationService` shape:
```ruby
ActiveRecord::Base.transaction do
  @profile.lock!
  # ... mutations ...
end

if error
  fail_with(error)
else
  ok(redemption)
end
rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
  Rails.logger.error("[Rewards::RedeemService] exception ... error=#{e.message}")
  fail_with(e.message)
```

**Result helpers** — from `app/services/application_service.rb:1-12`:
```ruby
class ApplicationService
  Result = Data.define(:success, :error, :data) do
    def success? = success
  end

  def self.call(...) = new(...).call

  private
  def ok(data = nil) = Result.new(success: true, error: nil, data: data)
  def fail_with(error) = Result.new(success: false, error: error, data: nil)
end
```

**Adaptation notes:**
- Module: `Profiles`. Class: `SetWishlistService < ApplicationService`. Path: `app/services/profiles/set_wishlist_service.rb`.
- Constructor: `initialize(profile:, reward:)` — `reward` may be `nil` to clear.
- Cross-family guard before the transaction (defense in depth — see Shared Pattern §1):
  ```ruby
  if @reward && @reward.family_id != @profile.family_id
    Rails.logger.info("[Profiles::SetWishlistService] failure cross_family")
    return fail_with("Reward não pertence a esta família")
  end
  ```
- Single mutation inside the transaction: `@profile.update!(wishlist_reward: @reward)` — note: passing the association (or `nil`), not `wishlist_reward_id`, so Rails clears the FK correctly.
- **Do NOT broadcast from this service.** Per CONTEXT.md `## Decisions / Realtime`, the broadcast is fired by `Profile#after_update_commit :broadcast_wishlist_card`. This avoids the double-broadcast pitfall in RESEARCH.md `## Open Questions Q2 / Assumption A6`.
- Return on success: `ok({ profile: @profile, reward: @reward })`.
- Logger prefix: `[Profiles::SetWishlistService]` (mirror `[Rewards::RedeemService]` start/success/failure log lines).

---

### `app/controllers/kid/wishlist_controller.rb` (controller, request-response)

**Analog:** `app/controllers/kid/rewards_controller.rb`

**Preamble + auth pattern** (lines 1-5):
```ruby
class Kid::RewardsController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout "kid"
```

**Family-scoped IDOR-safe lookup pattern** (line 22):
```ruby
@reward = Reward.where(family_id: current_profile.family_id).find(params[:id])
```

**Service call + dual-format respond_to pattern** (lines 24-46):
```ruby
result = Rewards::RedeemService.new(profile: current_profile, reward: @reward).call
if result.success?
  respond_to do |format|
    format.html { redirect_to kid_rewards_path, notice: "Resgate solicitado! Aguarde a aprovação." }
    format.turbo_stream
  end
else
  respond_to do |format|
    format.html { redirect_to kid_rewards_path, alert: "Você não tem estrelas suficientes para este prêmio." }
    format.turbo_stream {
      render turbo_stream: turbo_stream.update(:flash, "Saldo insuficiente.")
    }
  end
end
```

**Adaptation notes:**
- Class: `Kid::WishlistController < ApplicationController` (single-resource, two actions).
- Two actions: `#create` (params: `:reward_id`), `#destroy` (no params — clears).
- `#create` body:
  ```ruby
  reward = Reward.where(family_id: current_profile.family_id).find(params[:reward_id])
  result = Profiles::SetWishlistService.call(profile: current_profile, reward: reward)
  if result.success?
    respond_to do |fmt|
      fmt.html { redirect_to kid_rewards_path, notice: "Meta atualizada!" }
      fmt.turbo_stream { head :ok } # Profile callback already fired the replace
    end
  else
    redirect_to kid_rewards_path, alert: result.error
  end
  ```
- `#destroy` body: `Profiles::SetWishlistService.call(profile: current_profile, reward: nil)` (no `Reward.find`).
- **Never** call `current_profile.update(wishlist_reward_id: ...)` directly — violates CLAUDE.md C-1.

---

### `app/components/ui/wishlist_goal/component.rb` (ViewComponent)

**Analog:** `app/components/ui/kid_progress_card/component.rb` (shape) + `app/components/ui/pin_modal/component.rb` (minimal `attr_reader` example)

**Component class shape pattern** (`kid_progress_card/component.rb:1-42`):
```ruby
module Ui
  module KidProgressCard
    class Component < ApplicationComponent
      def initialize(kid:, awaiting_count: 0, missions_count: 0, manage: false)
        @kid = kid
        # ...
        super()
      end

      attr_reader :kid, :awaiting_count, :missions_count, :manage

      def palette
        @palette ||= Ui::SmileyAvatar::Component::COLOR_MAP[kid&.color.to_s] || ...
      end

      def points = kid.respond_to?(:points) ? kid.points.to_i : 0
      def level = [(points / 100) + 1, 1].max
      def xp_progress = points % 100
      def stars_to_next = 100 - xp_progress
    end
  end
end
```

**Adaptation notes:**
- Module: `Ui::WishlistGoal`. Class path: `app/components/ui/wishlist_goal/component.rb`.
- Constructor: `initialize(profile:)`. Set `@profile = profile`, `@reward = profile.wishlist_reward`. Call `super()` (no args — match `kid_progress_card`).
- Helpers (use endless-method style per `kid_progress_card`):
  - `def pinned? = @reward.present?`
  - `def progress_pct = pinned? ? [(@profile.points.to_f / @reward.cost * 100).round, 100].min : 0`
  - `def stars_remaining = pinned? ? [@reward.cost - @profile.points, 0].max : 0`
  - `def funded? = pinned? && @profile.points >= @reward.cost`
- Expose `attr_reader :profile, :reward`.

---

### `app/components/ui/wishlist_goal/component.html.erb` (template)

**Analog:** `app/components/ui/kid_progress_card/component.html.erb` (progress bar + `ls-card-3d`) + `app/views/kid/dashboard/index.html.erb:48-87` (level progress card structure)

**Card outer + 3D shadow pattern** (`kid_progress_card/component.html.erb:1-12`):
```erb
<div data-palette="<%= helpers.palette_for(kid) %>">
  <div class="bg-surface rounded-[16px] border-2 border-hairline p-4 flex items-center gap-4 ls-card-3d"
       style="box-shadow: var(--shadow-card);">
    ...
  </div>
</div>
```

**Progress bar pattern** (`kid_progress_card/component.html.erb:24-26`):
```erb
<div class="h-[14px] rounded-[8px] overflow-hidden mb-3 relative" style="background: var(--hairline);">
  <div class="h-full rounded-[8px]" style="width: <%= xp_progress %>%; background: <%= palette[:fill] %>; box-shadow: inset 0 -3px 0 rgba(0,0,0,0.15);"></div>
</div>
```

**Richer level-card progress bar pattern** (`app/views/kid/dashboard/index.html.erb:70-79`):
```erb
<div class="relative overflow-hidden" style="height: 18px; background: var(--hairline); border-radius: 10px;">
  <div class="h-full transition-all duration-500 relative"
       style="width: <%= @level_pct %>%; background: linear-gradient(90deg, var(--primary) 0%, var(--primary-soft) 100%); border-radius: 10px;">
    <% if @level_pct.positive? %>
      <div class="absolute right-1.5 top-1/2 -translate-y-1/2">
        <%= render Ui::Icon::Component.new(:star, size: 11, color: "white") %>
      </div>
    <% end %>
  </div>
</div>
```

**Star delta + supporting copy pattern** (`app/views/kid/dashboard/index.html.erb:81-86`):
```erb
<div class="flex items-center gap-1.5 mt-2.5">
  <%= render Ui::Icon::Component.new(:star, size: 14, color: "var(--star)") %>
  <span class="text-[12px] font-bold" style="color: var(--text);">
    Faltam <strong class="font-extrabold" style="color: var(--primary-2);"><%= pluralize(@level_remaining, "estrelinha") %></strong> pra subir!
  </span>
</div>
```

**Adaptation notes:**
- Wrap the entire template in `<%= turbo_frame_tag dom_id(@profile, :wishlist) do %> ... <% end %>` — required so the model callback's `broadcast_replace_to target: dom_id(self, :wishlist)` finds the frame.
- Two branches:
  - **Empty** (`unless pinned?`): tinted card with copy "Escolha um prêmio como meta ⭐" — link to `kid_rewards_path`. Use the dashed-border ghost style from `app/views/kid/dashboard/index.html.erb:139-144` ("Fez algo fora da lista?") as the visual analog.
  - **Filled** (`if pinned?`): card with title "Minha meta", reward icon (use `reward.respond_to?(:icon) && reward.icon.presence || reward.category&.icon.presence || "gift"` — same coalesce as `_affordable.html.erb:12`), `progress_pct` bar, "<%= profile.points %>/<%= reward.cost %>" text, "Faltam <%= stars_remaining %>⭐" copy, plus a `funded?`-gated "Resgatar agora" CTA link.
- "Resgatar agora" CTA: per RESEARCH.md Q4 recommendation, link to `kid_rewards_path(anchor: dom_id(reward))` (or open the existing redeem modal via `data: { ui_modal_id_param: "modal_#{dom_id(reward)}" }`) — do **not** duplicate the redeem ritual UI.
- Colors via tokens only (CLAUDE.md C-6): `var(--primary)`, `var(--primary-2)`, `var(--primary-soft)`, `var(--star)`, `var(--hairline)`, `var(--text)`, `var(--text-muted)`. **No hex.**
- Use `ls-card-3d` and `ls-btn-3d` utility classes from `theme.css` so press / `prefers-reduced-motion` are inherited (CLAUDE.md C-7, RESEARCH.md Pitfall 3).

---

### `app/components/ui/wishlist_goal/component.css` (colocated stylesheet)

**Analog:** `app/components/ui/pin_modal/component.css`

**Reduced-motion carve-out pattern** (`pin_modal/component.css` last lines):
```css
@media (prefers-reduced-motion: reduce) {
  .pin-dot, .pin-key { transition: none; }
}
```

**Keyframes for card pop / fade pattern**:
```css
.pin-card { animation: pin-card-pop .2s cubic-bezier(0.34, 1.56, 0.64, 1); }
@keyframes pin-card-pop { from { transform: scale(0.92); opacity: 0; } to { transform: scale(1); opacity: 1; } }
```

**Adaptation notes:**
- Scope all selectors under a unique class prefix (e.g. `.wishlist-goal__bar`, `.wishlist-goal__fill`) to avoid leakage — `pin-modal` uses `.pin-*` exactly the same way.
- Progress fill animation:
  ```css
  .wishlist-goal__fill { transition: width 600ms cubic-bezier(0.34, 1.56, 0.64, 1); }
  @media (prefers-reduced-motion: reduce) {
    .wishlist-goal__fill { transition: none; }
  }
  ```
- Add `@import "../../components/ui/wishlist_goal/component.css";` to `app/assets/entrypoints/application.css` (see "Modified files" §`application.css`).

---

### `app/views/kid/wishlist/_goal.html.erb` (broadcast partial)

**Analog:** `app/views/kid/dashboard/_pending_card.html.erb` (a kid-namespace partial that wraps a component) — visible in `index.html.erb:123` (`render "kid/dashboard/pending_card", profile_task: ..., index: i`).

**Pattern:** thin partial that just renders the component, so the broadcast (`partial: "kid/wishlist/goal", locals: { profile: profile }`) can re-render exactly the same DOM produced by the inline `<%= render Ui::WishlistGoal::Component.new(profile: current_profile) %>` on the dashboard.

```erb
<%# app/views/kid/wishlist/_goal.html.erb %>
<%= render Ui::WishlistGoal::Component.new(profile: profile) %>
```

**Adaptation notes:**
- Local variable name: `profile` (matches what `Profile#broadcast_wishlist_card` passes in `locals: { profile: self }`).
- File path **must** match the broadcast call exactly: `partial: "kid/wishlist/goal"` → `app/views/kid/wishlist/_goal.html.erb`.
- The `turbo_frame_tag dom_id(@profile, :wishlist)` wrapper lives **inside** the component template, not in this partial — this means both the initial render (on `kid/dashboard#index`) and the broadcast replace render the same frame markup. ✓

---

### `spec/services/profiles/set_wishlist_service_spec.rb` (service spec)

**Analog:** `spec/services/rewards/redeem_service_spec.rb`

**Spec scaffold pattern** (lines 1-7):
```ruby
require 'rails_helper'

RSpec.describe Rewards::RedeemService do
  let(:family) { create(:family) }
  let(:child) { create(:profile, :child, family: family, points: 100) }
  let(:reward) { create(:reward, family: family, cost: 70) }
```

**Result-shape assertions** (lines 26-29):
```ruby
result = described_class.new(profile: child, reward: reward).call
expect(result.success?).to be true
```

**Broadcast assertion pattern** (lines 31-41):
```ruby
context 'celebration broadcast' do
  it 'broadcasts a celebration partial with tier=big and reward_title in payload' do
    expect {
      described_class.new(profile: child, reward: reward).call
    }.to have_broadcasted_to("kid_#{child.id}")
      .with { |stream|
        expect(stream).to include('data-fx-event="celebrate"', 'data-fx-tier="big"')
        expect(stream).to include(reward.title)
      }
  end
end
```

**Adaptation notes:**
- File path: `spec/services/profiles/set_wishlist_service_spec.rb` (create the `profiles/` subdir).
- Cover three contexts (per CONTEXT.md):
  1. **Happy path** (same-family): `result.success?` is true; `child.reload.wishlist_reward` equals `reward`.
  2. **Cross-family rejection**: with `foreign_reward = create(:reward, family: create(:family))`, `result.success?` is false; `result.error` matches `/família/i`; `child.reload.wishlist_reward` is `nil`.
  3. **Clear (`reward: nil`)**: pre-set `child.update!(wishlist_reward: reward)` then call with `reward: nil`; assert `child.reload.wishlist_reward` is `nil`.
- Broadcast assertion (single test): the broadcast comes from the **`Profile` model callback**, not the service, so the matcher must trigger on the resulting state change. Pattern:
  ```ruby
  expect { described_class.call(profile: child, reward: reward) }
    .to have_broadcasted_to("kid_#{child.id}")
  ```
- Use `described_class.call(...)` (the `ApplicationService.call` class method) **or** `described_class.new(...).call` — the redeem spec uses `.new(...).call`; either is acceptable. Stay consistent within this file.

---

### `spec/requests/kid/wishlist_controller_spec.rb` (request spec)

**Analog:** `spec/requests/kid/wallet_and_rewards_spec.rb`

**Setup + sign-in pattern** (lines 1-12):
```ruby
require 'rails_helper'

RSpec.describe "Kid::Rewards", type: :request do
  let(:family) { create(:family) }
  let(:child) { create(:profile, :child, family: family, points: 100) }
  let(:reward) { create(:reward, family: family, cost: 50, title: "Sorvete") }

  before do
    host! "localhost"
    sign_in_as(child)
  end
```

**Action assertion pattern** (lines 22-31):
```ruby
describe "POST /kid/rewards/:id/redeem" do
  it "redeems a reward successfully" do
    expect {
      post redeem_kid_reward_path(reward)
    }.to change { child.reload.points }.by(-50)

    expect(response).to redirect_to(kid_rewards_path)
  end
```

**Adaptation notes:**
- Two `describe` blocks: `"POST /kid/wishlist"` and `"DELETE /kid/wishlist"`.
- Create case:
  ```ruby
  expect {
    post kid_wishlist_path, params: { reward_id: reward.id }
  }.to change { child.reload.wishlist_reward_id }.from(nil).to(reward.id)
  expect(response).to redirect_to(kid_rewards_path)
  ```
- Destroy case (preset `child.update!(wishlist_reward: reward)`):
  ```ruby
  expect {
    delete kid_wishlist_path
  }.to change { child.reload.wishlist_reward_id }.from(reward.id).to(nil)
  ```
- Cross-family 404: pass `params: { reward_id: foreign_reward.id }` and assert `flash[:alert]` is present (the controller's `Reward.where(family_id:...).find` raises `RecordNotFound` → `ApplicationController` handles it). Verify by reading the existing `not_found` handler if present, otherwise expect the rescue path to short-circuit.

---

### `spec/components/ui/wishlist_goal/component_spec.rb` (component spec)

**Analog:** `spec/components/ui/kid_progress_card/component_spec.rb`

**Component spec scaffold pattern** (full file):
```ruby
require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::KidProgressCard::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:kid) { create(:profile, :child, name: "Lila", points: 42) }

  it "renders kid name, balance, and missions count" do
    render_inline(described_class.new(kid: kid, awaiting_count: 0, missions_count: 3))
    expect(page).to have_text("Lila")
    expect(page).to have_text("42")
    expect(page).to have_text("3")
  end

  it "shows awaiting badge when count > 0" do
    render_inline(described_class.new(kid: kid, awaiting_count: 2, missions_count: 0))
    expect(page).to have_text("2 pendentes")
  end
```

**Adaptation notes:**
- Empty state: `child = build_stubbed(:profile, :child, points: 30)` (no `wishlist_reward`). Render. Expect `have_text("Escolha um prêmio")`.
- Filled below funded: `child = create(:profile, :child, points: 50)`; `reward = create(:reward, cost: 100); child.update!(wishlist_reward: reward)`. Expect `have_text("Minha meta")`, `have_text("50/100")`, `have_text("Faltam 50")`. Should **not** have text matching `/resgatar agora/i`.
- Filled funded: `points: 100, reward.cost: 100`. Expect `have_text("Resgatar agora")` and `have_text(/pronto/i)` (or whatever final copy is chosen — keep within Claude's discretion).
- Use `build_stubbed` over `create` where possible for speed (per analog line 27).

---

### `spec/system/kid_wishlist_spec.rb` (system spec)

**Analog:** `spec/system/reward_redemption_flow_spec.rb`

**Setup + dual-session pattern** (full top, lines 1-9):
```ruby
require "rails_helper"

RSpec.describe "Reward Redemption Flow", type: :system do
  let!(:family) { create(:family, name: "Teste") }
  let!(:parent) { create(:profile, :parent, family: family, name: "Papai") }
  let!(:child) { create(:profile, :child, family: family, name: "Filhote", points: 500) }
  let!(:reward) { create(:reward, family: family, title: "Sorvete", cost: 300) }

  it "permite ao filho resgatar uma recompensa e ao pai aprovar" do
    sign_in_as_child(child)
    visit kid_rewards_path
```

**Sign-in helpers** — defined in `spec/support/system_auth_helpers.rb:37,41` (`sign_in_as_child(profile, pin: "1234")`, `sign_in_as_parent(profile, pin: "1234")`).

**Modal interaction helper** — `open_modal_and_click("modal_<dom_id>", "<button text>")` from `spec/support/system_auth_helpers.rb:48`.

**Adaptation notes:**
- Title in pt-BR: `"Wishlist Goal Flow"` describe + per-it `"permite ao filho fixar uma meta e ver o progresso"` style (mirror `permite ao filho resgatar`).
- Steps (per CONTEXT.md `## Decisions / Testing` "system spec"):
  1. `sign_in_as_child(child)`; `visit kid_rewards_path`.
  2. `within("[data-reward-id='#{reward.id}']") { click_on "Definir como meta" }` — assumes the pin-toggle button exposes a stable selector.
  3. `visit kid_root_path`; expect `have_content("Minha meta")`, `have_content(reward.title)`, `have_content("Faltam #{reward.cost - child.points}")`.
  4. (Optional second `it`) Sign in as parent, complete a task to bump `child.points`, return to `kid_root_path`, assert progress changed.
- Use `let!` (eager) to ensure the reward exists before the kid visits the page (mirrors analog).

---

### MODIFIED: `app/models/profile.rb`

**Pattern source (extending self):** `app/models/profile.rb:42` and `:71-99` (existing `broadcast_points` callback).

**Existing pattern** (line 42):
```ruby
after_update_commit :broadcast_points, if: :saved_change_to_points?
```

**Existing broadcast helper** (lines 71-99):
```ruby
def broadcast_points
  renderer = ApplicationController.renderer
  inner_html = renderer.render(...)
  broadcast_update_to self, "notifications", target: "profile_points_#{id}", html: inner_html.html_safe
  broadcast_append_to self, "notifications", target: "body", html: ...
end
```

**Adaptation notes:**
- After line 28 (`belongs_to :family`), add: `belongs_to :wishlist_reward, class_name: "Reward", optional: true` — `optional: true` is mandatory (Pitfall 1; mirrors `belongs_to :global_task, optional: true` in `app/models/profile_task.rb`).
- After line 42, add **one** new callback (single-line condition combining both columns avoids two callbacks doing the same work):
  ```ruby
  after_update_commit :broadcast_wishlist_card,
                      if: -> { saved_change_to_points? || saved_change_to_wishlist_reward_id? }
  ```
- After the existing `broadcast_points` private method (line 99), add:
  ```ruby
  def broadcast_wishlist_card
    Turbo::StreamsChannel.broadcast_replace_to(
      "kid_#{id}",
      target: ActionView::RecordIdentifier.dom_id(self, :wishlist),
      partial: "kid/wishlist/goal",
      locals: { profile: self }
    )
  rescue StandardError => e
    Rails.logger.warn("[Profile##{id}] wishlist broadcast failed: #{e.message}")
  end
  ```
- The `rescue StandardError` mirrors the resilience pattern from `Tasks::ApproveService#broadcast_celebration` (lines 89-91) and `Rewards::RedeemService#broadcast_celebration` (lines 80-82).
- Use `broadcast_replace_to` (not `update_to` like `broadcast_points`) because the entire frame contents change shape between empty/filled/funded states — see RESEARCH.md `## State of the Art`.

---

### MODIFIED: `app/services/rewards/redeem_service.rb`

**Pattern source (extending self):** lines 16-48 (the existing transaction).

**Adaptation notes — surgical addition between line 33 and line 35:**
```ruby
@profile.decrement!(:points, @reward.cost)

# NEW: auto-clear wishlist if redeeming the pinned reward (must stay inside transaction)
if @profile.wishlist_reward_id == @reward.id
  @profile.update!(wishlist_reward_id: nil)
end

redemption = Redemption.create!(
  profile: @profile,
  reward: @reward,
  points: @reward.cost,
  status: :pending
)
```

- The `update!` is inside the existing `ActiveRecord::Base.transaction { @profile.lock! ... }` block, so a failure rolls back the `decrement!` too (Pitfall 4 in RESEARCH.md).
- No new broadcast call is needed — the `Profile` model callback fires on `wishlist_reward_id` change automatically.
- **Do not** add a separate broadcast in `broadcast_celebration` for the wishlist card — model callback covers it.

---

### MODIFIED: `app/views/kid/dashboard/index.html.erb`

**Pattern source (self):** the level-progress card at lines 49-87 ends; the next section heading begins at line 90.

**Adaptation notes:**
- Insert exactly one line between line 87 (closing `</div>` of the level card) and line 89 (`<%# ── Section heading + counter ── %>`):
  ```erb
  <%# ── Wishlist goal card ── %>
  <%= render Ui::WishlistGoal::Component.new(profile: current_profile) %>
  ```
- Match adjacent vertical rhythm: the level card has `class="ls-card-3d mb-5 z-2 shrink-0"`. Either give the wishlist component the same outer margin (preferred — bake it into the component template wrapper) or wrap the render in a `<div class="mb-5 z-2 shrink-0">`. Pick the same approach the existing dashboard uses around line 89 to avoid layout drift.

---

### MODIFIED: `app/views/kid/rewards/_affordable.html.erb` and `_locked.html.erb`

**Pattern source (self):** the existing `<button data-controller="ui-modal">` overlay button on each card (`_affordable.html.erb:14-22`, `_locked.html.erb:16-22`).

**Existing pin-by-data-id pattern** — already present: `data-filter-tabs-target="item" data-panels="all <%= reward.category_id %>"` on the wrapper div. Add a stable selector for the system spec:

**Adaptation notes:**
- Wrap each existing card in a containing `<div data-reward-id="<%= reward.id %>" ...>` so the system spec can use `within("[data-reward-id='#{reward.id}']")` (the analog `kid_flow_spec.rb` already uses this kind of locator implicitly via `dom_id`).
- Add a small icon button positioned absolutely top-right (similar to the existing "✓ Pode" badge at `_affordable.html.erb:20-23`):
  ```erb
  <% pinned_here = current_profile.wishlist_reward_id == reward.id %>
  <% if pinned_here %>
    <%= button_to kid_wishlist_path, method: :delete,
                  form: { data: { turbo: true } },
                  class: "ls-btn-3d ...",
                  aria: { label: "Remover meta" } do %>
      <%= render Ui::Icon::Component.new(:star, size: 14, color: "var(--star)") %>
      <span>Remover meta</span>
    <% end %>
  <% else %>
    <%= button_to kid_wishlist_path, method: :post,
                  params: { reward_id: reward.id },
                  form: { data: { turbo: true } },
                  class: "ls-btn-3d ...",
                  aria: { label: "Definir como meta" } do %>
      <%= render Ui::Icon::Component.new(:star, size: 14, color: "currentColor") %>
      <span>Definir como meta</span>
    <% end %>
  <% end %>
  ```
- The `button_to` form approach mirrors `index.html.erb:151-157` (the existing "Sim, quero!" submit button). Plain form, Turbo handles the round-trip; the `Profile` callback re-renders the wishlist card on completion. RESEARCH.md `## Don't Hand-Roll` recommends this over a Stimulus controller.
- Stop event-bubbling so the click doesn't also open the redeem modal: wrap the toggle button in `data-action="click->ui-modal#stop"` **only if** the existing `ui-modal` controller has a `stop` action; otherwise use `e.stopPropagation` via a tiny inline `data-controller` or position the toggle outside the modal-trigger button. Verify against `app/assets/controllers/ui_modal_controller.js` before implementing — small risk: the cleanest solution is to put the toggle button **outside** the existing `<button data-action="click->ui-modal#open">` element so clicks don't compete.

---

### MODIFIED: `app/components/ui/kid_progress_card/component.{rb,html.erb}`

**Pattern source (self):** the existing flex row at `component.html.erb:28-43` ("X saldo / Y ativas / Z pendentes").

**Adaptation notes — `.rb`:**
- Add helper:
  ```ruby
  def wishlist_reward
    kid.respond_to?(:wishlist_reward) ? kid.wishlist_reward : nil
  end
  ```
- N+1 prevention: the `Parent::DashboardController#index` controller (already exists at `app/controllers/parent/dashboard_controller.rb`) runs `@children = @family.profiles.child` (line 9). Update to `@children = @family.profiles.child.includes(:wishlist_reward)` (RESEARCH.md Pitfall 5).

**Adaptation notes — `.html.erb`:**
- Insert a new line inside the `flex flex-wrap` row at line 28, **before** the `<% if awaiting_count.to_i > 0 %>` block at line 37:
  ```erb
  <% if wishlist_reward %>
    <span class="flex items-center gap-1.5" style="color: var(--text-muted);">
      <%= render Ui::Icon::Component.new("target", size: 14, color: "var(--primary-2)") %>
      Meta: <%= wishlist_reward.title %>
    </span>
  <% else %>
    <span class="flex items-center gap-1.5 italic" style="color: var(--text-soft);">Sem meta</span>
  <% end %>
  ```
- Keep the read-only requirement: no link, no button, no `button_to`. CONTEXT.md `## Decisions / UI` says parent visibility is read-only.

---

### MODIFIED: `config/routes.rb`

**Pattern source (self):** lines 44-53 — existing `namespace :kid` block.

**Existing pattern**:
```ruby
namespace :kid do
  root to: "dashboard#index"
  resources :missions, only: %i[new create] do
    member { patch :complete }
  end
  resources :rewards, only: [ :index ] do
    member { post :redeem }
  end
  resources :wallet, only: [ :index ]
end
```

**Adaptation notes:**
- Add one line inside the existing `namespace :kid do ... end` block (after line 52, before the closing `end`):
  ```ruby
  resource :wishlist, only: %i[create destroy], controller: "wishlist"
  ```
- Note the singular `resource` (not plural) — the wishlist is a singleton resource per profile (no `:id` in URL).
- This generates: `POST /kid/wishlist` → `Kid::WishlistController#create`, `DELETE /kid/wishlist` → `Kid::WishlistController#destroy`, `kid_wishlist_path` helper.

---

### MODIFIED: `app/assets/entrypoints/application.css`

**Pattern source (self):** lines 25-36 — existing `@import "../../components/ui/.../component.css";` lines.

**Existing pattern**:
```css
@import "../../components/ui/bg_shapes/component.css";
@import "../../components/ui/btn/btn.css";
...
@import "../../components/ui/pin_modal/component.css";
@import "../../components/ui/profile_picker/component.css";
```

**Adaptation notes:**
- Add one line, alphabetically near the existing imports (between `tooltip` and the closing `/* Vendors */` block, or grouped where convenient):
  ```css
  @import "../../components/ui/wishlist_goal/component.css";
  ```
- No other changes to this file.

---

### MODIFIED: `spec/services/rewards/redeem_service_spec.rb`

**Pattern source (self):** the existing `describe '#call'` blocks at lines 8-146.

**Adaptation notes:**
- Add a new `context` block (e.g. between line 64 and line 66 — alongside other balance contexts):
  ```ruby
  context 'when the redeemed reward is the kid\'s pinned wishlist' do
    let(:family) { create(:family) }
    let(:child)  { create(:profile, :child, family: family, points: 100) }
    let(:reward) { create(:reward, family: family, cost: 70) }

    before { child.update!(wishlist_reward: reward) }

    it 'clears wishlist_reward_id inside the redeem transaction' do
      expect {
        described_class.new(profile: child, reward: reward).call
      }.to change { child.reload.wishlist_reward_id }.from(reward.id).to(nil)
    end

    it 'does not clear wishlist when redeeming a different reward' do
      other = create(:reward, family: family, cost: 30)
      expect {
        described_class.new(profile: child, reward: other).call
      }.not_to change { child.reload.wishlist_reward_id }
    end
  end
  ```

---

## Shared Patterns

### §1 Cross-family security check (defense in depth)

**Source:** `app/controllers/kid/rewards_controller.rb:22` (controller-layer scope) + new service-layer guard.

**Pattern (controller layer):**
```ruby
@reward = Reward.where(family_id: current_profile.family_id).find(params[:id])
```

**Pattern (service layer guard):**
```ruby
if @reward && @reward.family_id != @profile.family_id
  return fail_with("Reward não pertence a esta família")
end
```

**Apply to:**
- `Kid::WishlistController#create` — controller-layer scope on `Reward.find`.
- `Profiles::SetWishlistService#call` — service-layer guard before the transaction.

### §2 Service `Result` contract

**Source:** `app/services/application_service.rb:1-12`.

**Pattern:**
```ruby
def call
  # ... validation guards: return fail_with("...")
  ActiveRecord::Base.transaction do
    # ... mutations ...
  end
  ok({ profile: @profile, reward: @reward })
rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
  Rails.logger.error("[Module::Service] exception #{e.message}")
  fail_with(e.message)
end
```

**Apply to:** Every service in this phase (currently just `Profiles::SetWishlistService`, but the augmented `Rewards::RedeemService` already follows it).

### §3 Turbo Stream broadcast (synchronous, rescued)

**Source:** `app/services/tasks/approve_service.rb:83-91`, `app/services/rewards/redeem_service.rb:74-82`.

**Pattern:**
```ruby
Turbo::StreamsChannel.broadcast_replace_to(
  "kid_#{@profile.id}",
  target: ActionView::RecordIdentifier.dom_id(@profile, :wishlist),
  partial: "kid/wishlist/goal",
  locals: { profile: @profile }
)
rescue StandardError => e
  Rails.logger.warn("[<Source>] broadcast failed ... error=#{e.message}")
```

**Apply to:** `Profile#broadcast_wishlist_card` (model callback). Synchronous — never `_later_to`. Always wrap in `rescue StandardError` so a Cable/serializer hiccup doesn't roll back the transaction.

### §4 Authentication / authorization for kid actions

**Source:** `app/controllers/concerns/authenticatable.rb:42-46` (`require_child!`) and `app/controllers/kid/rewards_controller.rb:1-5` (preamble).

**Pattern:**
```ruby
class Kid::WishlistController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout "kid"
end
```

**Apply to:** `Kid::WishlistController`.

### §5 Duolingo design tokens (no raw hex)

**Source:** CLAUDE.md C-6, DESIGN.md, `app/assets/stylesheets/tailwind/theme.css`.

**Pattern:** Every color/font/radius/shadow value via CSS variables:
- Colors: `var(--primary)`, `var(--primary-2)`, `var(--primary-soft)`, `var(--star)`, `var(--star-2)`, `var(--star-soft)`, `var(--hairline)`, `var(--text)`, `var(--text-muted)`, `var(--text-soft)`, `var(--surface)`, `var(--c-amber-dark)`, etc.
- Fonts: `font-display` (Tailwind utility wired to Nunito).
- Radii: `var(--r-xl)`, etc.
- Shadows: `var(--shadow-card)`, or inline `0 4px 0 var(--primary-2)` for the 3D contract.

**Apply to:** `app/components/ui/wishlist_goal/component.{html.erb,css}` and any HTML edited in `_affordable.html.erb` / `_locked.html.erb` / `kid_progress_card/component.html.erb`.

### §6 3D motion contract + reduced-motion carve-out

**Source:** `app/components/ui/pin_modal/component.css` (last `@media` block) and DESIGN.md §5.

**Pattern:**
```css
.wishlist-goal__fill { transition: width 600ms cubic-bezier(0.34, 1.56, 0.64, 1); }
@media (prefers-reduced-motion: reduce) {
  .wishlist-goal__fill { transition: none; }
}
```

**Apply to:** `app/components/ui/wishlist_goal/component.css`. Use `ls-card-3d` and `ls-btn-3d` utility classes elsewhere (they already include the carve-out).

### §7 ViewComponent shape (initialize, attr_reader, endless helper methods)

**Source:** `app/components/ui/kid_progress_card/component.rb:1-42`.

**Pattern:** see `Ui::WishlistGoal::Component` adaptation notes above.

**Apply to:** `Ui::WishlistGoal::Component`.

### §8 PIN-gated request spec sign-in

**Source:** `spec/requests/kid/wallet_and_rewards_spec.rb:8-11`.

**Pattern:**
```ruby
before do
  host! "localhost"
  sign_in_as(child)
end
```

**Apply to:** `spec/requests/kid/wishlist_controller_spec.rb`.

### §9 PIN-gated system spec sign-in

**Source:** `spec/system/reward_redemption_flow_spec.rb` + `spec/support/system_auth_helpers.rb:37,41`.

**Pattern:**
```ruby
sign_in_as_child(child)
visit kid_rewards_path
```

**Apply to:** `spec/system/kid_wishlist_spec.rb`.

---

## No Analog Found

None. Every file in this phase has a strong in-repo analog.

---

## Metadata

**Analog search scope:**
- `app/services/{rewards,tasks,profiles}/`
- `app/controllers/kid/`, `app/controllers/concerns/`, `app/controllers/parent/`
- `app/components/ui/{balance_chip,mission_card,kid_progress_card,pin_modal}/`
- `app/views/kid/{dashboard,rewards,shared}/`, `app/views/parent/dashboard/`
- `app/models/profile.rb`, `app/models/profile_task.rb` (for `optional: true` belongs_to)
- `db/migrate/` (last two migrations as canonical Rails 8.1 syntax)
- `spec/services/`, `spec/requests/kid/`, `spec/components/ui/kid_progress_card/`, `spec/system/`, `spec/support/system_auth_helpers.rb`
- `config/routes.rb`, `app/assets/entrypoints/application.css`

**Files scanned:** ~25 (including the directory listings used to confirm spec paths and component layouts).

**Pattern extraction date:** 2026-04-30

**Notes for the planner:**
- `spec/models/profile_spec.rb` already exists. The plan should **append** wishlist association tests + nullify-on-delete + callback assertions to the existing `RSpec.describe Profile` block, not create a new file.
- The `data-reward-id` selector recommended for `_affordable.html.erb` / `_locked.html.erb` is a small new convention; if the planner prefers, the existing wrapper element can use the standard Rails `id: dom_id(reward)` instead and the system spec can `within("##{dom_id(reward)}")` — equally valid.
- For the redeem-modal "Resgatar agora" CTA in the wishlist card, the simplest path is `link_to kid_rewards_path(anchor: dom_id(reward))` (browser scrolls to the reward card; user taps it to open the existing modal). RESEARCH.md Q4 recommendation.
