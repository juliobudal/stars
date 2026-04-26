# Kid UI Vibrancy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a centralized FX layer (motion tokens + `fx_controller` + `Ui::Celebration` service) with branded modal variants and tiered celebrations across the kid-facing UI.

**Architecture:** Three layers — (1) CSS motion tokens in `app/assets/stylesheets/tailwind/motion.css`, (2) Stimulus `fx_controller` driven by Motion One that observes `data-fx-event` attributes, (3) Ruby decision module `Ui::Celebration` that tags broadcasted Turbo Stream partials with FX metadata. Existing services (`Tasks::ApproveService`, `Rewards::RedeemService`, `Tasks::CompleteService`) get extended to broadcast celebration partials over the existing `"kid_#{profile.id}"` channel.

**Tech Stack:** Rails 8.1, ViewComponent 4.7, Stimulus, Turbo Streams, Motion One (~3.8kb, new dep), `canvas-confetti` (already in `package.json`), Tailwind 4, RSpec.

**Spec:** `docs/superpowers/specs/2026-04-26-kid-ui-vibrancy-design.md`

---

## File Plan

### Create

| Path | Responsibility |
|---|---|
| `app/assets/stylesheets/tailwind/motion.css` | Motion tokens (springs, durations) + utility classes + reduced-motion guard |
| `app/assets/controllers/fx_controller.js` | Single FX dispatcher — MutationObserver, Motion One driver, reduced-motion branching |
| `app/services/ui/celebration.rb` | Pure decision module — `tier_for(event_type, **ctx)` returns `:big | :small | :none` |
| `app/services/streaks/check_service.rb` | Read-only milestone detector — streak (3/7/14d) + threshold cross (50/100/250★) |
| `app/components/ui/toast/component.rb` | Lightweight toast component |
| `app/components/ui/toast/component.html.erb` | Toast template |
| `app/views/kid/shared/_celebration.html.erb` | Server-rendered celebration partial (broadcast target) |
| `app/views/kid/shared/_fx_stage.html.erb` | Container `<div id="fx_stage">` for streamed celebrations |
| `spec/services/ui/celebration_spec.rb` | Tier decision tests |
| `spec/services/streaks/check_service_spec.rb` | Milestone detection tests |
| `spec/components/ui/toast_component_spec.rb` | Toast variants test |

### Modify

| Path | Change |
|---|---|
| `package.json` | Add `motion` dep (Motion One) |
| `app/components/ui/modal/component.rb` | Add `variant:` arg (`:default`, `:success`, `:confirm-destructive`, `:celebration`) |
| `app/components/ui/modal/component.yml` | Document new arg |
| `app/views/layouts/kid.html.erb` | Mount `data-controller="fx"` on `<body>`, render `_fx_stage` partial |
| `app/services/tasks/approve_service.rb` | Compute tier + streak result, broadcast celebration partial |
| `app/services/rewards/redeem_service.rb` | Same — gold-palette payload |
| `app/services/tasks/complete_service.rb` | Detect "all daily missions cleared" condition, broadcast small toast |
| `app/components/ui/balance_chip/component.rb` | Stamp `id="balance_chip_<profile_id>"` for broadcast targeting + accept `fx_event` data attrs |
| `spec/services/tasks/approve_service_spec.rb` | Extend — broadcast partial includes `data-fx-event` + `data-fx-tier` |
| `spec/services/rewards/redeem_service_spec.rb` | Extend — same |
| `spec/components/ui/modal_component_spec.rb` | Extend — render each `variant:` |
| `app/assets/stylesheets/tailwind/animations.css` | Audit — note about kid-relevant utilities migrating to motion.css (handled in Task 13) |

### Delete

| Path | Reason |
|---|---|
| `app/assets/controllers/celebration_controller.js` | Logic absorbed by `fx_controller` (Task 14) |

---

## Task 1: Add Motion One dependency

**Files:**
- Modify: `package.json`

- [ ] **Step 1: Add the dep**

Run:
```bash
docker compose exec web yarn add motion@^11.11.0
```

- [ ] **Step 2: Verify installed**

Run: `docker compose exec web cat package.json | grep '"motion"'`
Expected: line containing `"motion": "^11.11.0"`

- [ ] **Step 3: Commit**

```bash
git add package.json yarn.lock
git commit -m "chore(deps): add motion (Motion One) for FX orchestration"
```

---

## Task 2: Motion tokens + utilities CSS

**Files:**
- Create: `app/assets/stylesheets/tailwind/motion.css`
- Modify: `app/assets/stylesheets/application.css` (import the new file)

- [ ] **Step 1: Find the import location**

Read: `app/assets/stylesheets/application.css`
Note where `tailwind/animations.css` is imported — add new import next to it.

- [ ] **Step 2: Create `motion.css`**

Write to `app/assets/stylesheets/tailwind/motion.css`:

```css
@layer base {
  :root {
    --ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);
    --ease-spring-soft: cubic-bezier(0.22, 1.4, 0.36, 1);
    --ease-snap: cubic-bezier(0.4, 0, 0.2, 1);
    --dur-fast: 120ms;
    --dur-base: 240ms;
    --dur-pop: 380ms;
  }
}

@layer utilities {
  .anim-press {
    transition: transform var(--dur-fast) var(--ease-spring);
  }
  .anim-press:active {
    transform: scale(0.96);
  }

  .anim-tile {
    transition:
      transform var(--dur-base) var(--ease-spring-soft),
      box-shadow var(--dur-base) var(--ease-snap);
  }
  .anim-tile:hover {
    transform: translateY(-2px);
    box-shadow: 0 12px 24px rgba(99, 82, 255, 0.14);
  }

  .anim-pop-in {
    animation: fxPopIn var(--dur-pop) var(--ease-spring) both;
  }
  @keyframes fxPopIn {
    from {
      opacity: 0;
      transform: scale(0.9) translateY(8px);
    }
    to {
      opacity: 1;
      transform: none;
    }
  }

  .anim-pulse-once {
    animation: fxPulseOnce var(--dur-pop) var(--ease-spring) both;
  }
  @keyframes fxPulseOnce {
    0%, 100% { transform: scale(1); }
    50% { transform: scale(1.12); }
  }

  .anim-shake {
    animation: fxShake 360ms var(--ease-snap) both;
  }
  @keyframes fxShake {
    0%, 100% { transform: translateX(0); }
    20% { transform: translateX(-6px); }
    40% { transform: translateX(6px); }
    60% { transform: translateX(-4px); }
    80% { transform: translateX(4px); }
  }

  .anim-bounce-once {
    animation: fxBounceOnce 500ms var(--ease-spring) both;
  }
  @keyframes fxBounceOnce {
    0% { transform: translateY(0); }
    40% { transform: translateY(-10px); }
    70% { transform: translateY(-4px); }
    100% { transform: translateY(0); }
  }

  .anim-fade-up {
    animation: fxFadeUp var(--dur-base) var(--ease-spring-soft) both;
  }
  @keyframes fxFadeUp {
    from { opacity: 0; transform: translateY(8px); }
    to { opacity: 1; transform: none; }
  }

  .anim-shimmer {
    background: linear-gradient(
      90deg,
      rgba(255,255,255,0) 0%,
      rgba(255,255,255,0.4) 50%,
      rgba(255,255,255,0) 100%
    );
    background-size: 200% 100%;
    animation: fxShimmer 1.4s linear infinite;
  }
  @keyframes fxShimmer {
    from { background-position: 200% 0; }
    to { background-position: -200% 0; }
  }
}

@layer utilities {
  @media (prefers-reduced-motion: reduce) {
    .anim-press,
    .anim-tile,
    .anim-pop-in,
    .anim-pulse-once,
    .anim-shake,
    .anim-bounce-once,
    .anim-fade-up,
    .anim-shimmer {
      animation: none !important;
      transition: none !important;
    }
    .anim-tile:hover {
      transform: none;
      box-shadow: none;
    }
  }
}
```

- [ ] **Step 3: Import from `application.css`**

Add (next to existing `tailwind/animations.css` import):

```css
@import "./tailwind/motion.css";
```

- [ ] **Step 4: Verify build**

Run: `docker compose exec web bin/vite build`
Expected: success, no CSS parse errors.

- [ ] **Step 5: Commit**

```bash
git add app/assets/stylesheets/tailwind/motion.css app/assets/stylesheets/application.css
git commit -m "feat(ui): motion tokens + utility classes (kid UI vibrancy)"
```

---

## Task 3: `Ui::Celebration` service — write failing test

**Files:**
- Test: `spec/services/ui/celebration_spec.rb`

- [ ] **Step 1: Write the failing test**

Write to `spec/services/ui/celebration_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe Ui::Celebration do
  describe '.tier_for' do
    it 'returns :big for :approved' do
      expect(described_class.tier_for(:approved)).to eq(:big)
    end

    it 'returns :big for :redeemed' do
      expect(described_class.tier_for(:redeemed)).to eq(:big)
    end

    it 'returns :big for :streak' do
      expect(described_class.tier_for(:streak)).to eq(:big)
    end

    it 'returns :big for :threshold' do
      expect(described_class.tier_for(:threshold)).to eq(:big)
    end

    it 'returns :big for :all_cleared' do
      expect(described_class.tier_for(:all_cleared)).to eq(:big)
    end

    it 'returns :small for :done_tapped' do
      expect(described_class.tier_for(:done_tapped)).to eq(:small)
    end

    it 'returns :small for :reset' do
      expect(described_class.tier_for(:reset)).to eq(:small)
    end

    it 'returns :small for :reward_unlocked' do
      expect(described_class.tier_for(:reward_unlocked)).to eq(:small)
    end

    it 'returns :none for an unknown event' do
      expect(described_class.tier_for(:something_else)).to eq(:none)
    end

    it 'accepts an arbitrary context hash without raising' do
      expect { described_class.tier_for(:approved, profile: nil, points: 5) }.not_to raise_error
    end
  end
end
```

- [ ] **Step 2: Run test — verify failure**

Run: `docker compose exec web bundle exec rspec spec/services/ui/celebration_spec.rb`
Expected: FAIL with `uninitialized constant Ui::Celebration`.

---

## Task 4: `Ui::Celebration` service — implement

**Files:**
- Create: `app/services/ui/celebration.rb`

- [ ] **Step 1: Implement minimal module**

Write to `app/services/ui/celebration.rb`:

```ruby
module Ui
  module Celebration
    BIG_EVENTS = %i[approved redeemed streak threshold all_cleared].freeze
    SMALL_EVENTS = %i[done_tapped reset reward_unlocked].freeze

    def self.tier_for(event_type, **_context)
      sym = event_type.to_sym
      return :big if BIG_EVENTS.include?(sym)
      return :small if SMALL_EVENTS.include?(sym)

      :none
    end
  end
end
```

- [ ] **Step 2: Run tests — verify pass**

Run: `docker compose exec web bundle exec rspec spec/services/ui/celebration_spec.rb`
Expected: 10 examples, 0 failures.

- [ ] **Step 3: Commit**

```bash
git add app/services/ui/celebration.rb spec/services/ui/celebration_spec.rb
git commit -m "feat(services): Ui::Celebration tier decision module"
```

---

## Task 5: `Streaks::CheckService` — write failing test

**Files:**
- Test: `spec/services/streaks/check_service_spec.rb`

- [ ] **Step 1: Write the failing test**

Write to `spec/services/streaks/check_service_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe Streaks::CheckService do
  let(:family) { create(:family) }
  let(:profile) { create(:profile, :child, family: family, points: 100) }

  describe '.call' do
    context 'when no threshold or streak hit' do
      it 'returns nil' do
        result = described_class.call(profile, points_before: 100, points_after: 110)
        expect(result).to be_nil
      end
    end

    context 'when crossing a threshold (50)' do
      it 'returns :threshold tier with the threshold value' do
        result = described_class.call(profile, points_before: 49, points_after: 55)
        expect(result).to be_a(Hash)
        expect(result[:tier]).to eq(:threshold)
        expect(result[:payload][:threshold]).to eq(50)
      end
    end

    context 'when crossing 100' do
      it 'returns :threshold with 100' do
        result = described_class.call(profile, points_before: 99, points_after: 105)
        expect(result[:payload][:threshold]).to eq(100)
      end
    end

    context 'when crossing two thresholds at once (49 -> 105)' do
      it 'returns the highest crossed threshold' do
        result = described_class.call(profile, points_before: 49, points_after: 105)
        expect(result[:payload][:threshold]).to eq(100)
      end
    end

    context 'when streak day is hit (3 consecutive days of earn logs)' do
      before do
        # Build 3 consecutive days of earn logs ending today
        2.downto(0) do |days_ago|
          create(:activity_log, profile: profile, log_type: :earn, points: 5, created_at: days_ago.days.ago)
        end
      end

      it 'returns :streak tier with day count' do
        result = described_class.call(profile, points_before: 95, points_after: 100)
        # streak wins over threshold per priority: streak > threshold > approved
        expect(result[:tier]).to eq(:streak)
        expect(result[:payload][:days]).to eq(3)
      end
    end

    context 'when streak gap breaks the chain' do
      before do
        create(:activity_log, profile: profile, log_type: :earn, points: 5, created_at: 0.days.ago)
        create(:activity_log, profile: profile, log_type: :earn, points: 5, created_at: 1.day.ago)
        # gap on day 2 (no log)
        create(:activity_log, profile: profile, log_type: :earn, points: 5, created_at: 3.days.ago)
      end

      it 'does NOT return :streak (chain broken)' do
        result = described_class.call(profile, points_before: 5, points_after: 10)
        expect(result).to be_nil
      end
    end

    context 'when service raises internally' do
      it 'returns nil and logs warning' do
        allow(profile).to receive(:activity_logs).and_raise(StandardError, "boom")
        expect(Rails.logger).to receive(:warn).with(/Streaks::CheckService/)
        result = described_class.call(profile, points_before: 0, points_after: 5)
        expect(result).to be_nil
      end
    end
  end
end
```

- [ ] **Step 2: Run test — verify failure**

Run: `docker compose exec web bundle exec rspec spec/services/streaks/check_service_spec.rb`
Expected: FAIL with `uninitialized constant Streaks`.

---

## Task 6: `Streaks::CheckService` — implement

**Files:**
- Create: `app/services/streaks/check_service.rb`

- [ ] **Step 1: Implement service**

Write to `app/services/streaks/check_service.rb`:

```ruby
module Streaks
  class CheckService
    THRESHOLDS = [50, 100, 250].freeze
    STREAK_MILESTONES = [3, 7, 14].freeze

    def self.call(...)
      new(...).call
    end

    def initialize(profile, points_before:, points_after:)
      @profile = profile
      @points_before = points_before.to_i
      @points_after = points_after.to_i
    end

    def call
      streak = detect_streak
      threshold = detect_threshold

      # Priority: streak > threshold > nil. Lower-priority dropped on collision.
      return { tier: :streak, payload: { days: streak } } if streak
      return { tier: :threshold, payload: { threshold: threshold } } if threshold

      nil
    rescue StandardError => e
      Rails.logger.warn("[Streaks::CheckService] error profile_id=#{@profile&.id} error=#{e.message}")
      nil
    end

    private

    def detect_threshold
      crossed = THRESHOLDS.select { |t| @points_before < t && @points_after >= t }
      crossed.max
    end

    def detect_streak
      logs = @profile.activity_logs
                     .where(log_type: :earn)
                     .where('created_at >= ?', 14.days.ago.beginning_of_day)
                     .order(created_at: :desc)

      days = logs.pluck(:created_at).map { |t| t.to_date }.uniq.sort.reverse
      return nil if days.empty?

      # Count consecutive days ending today
      today = Date.current
      return nil if days.first != today

      streak = 1
      days.each_cons(2) do |a, b|
        if (a - b).to_i == 1
          streak += 1
        else
          break
        end
      end

      STREAK_MILESTONES.include?(streak) ? streak : nil
    end
  end
end
```

- [ ] **Step 2: Run tests — verify pass**

Run: `docker compose exec web bundle exec rspec spec/services/streaks/check_service_spec.rb`
Expected: 7 examples, 0 failures.

- [ ] **Step 3: Commit**

```bash
git add app/services/streaks/check_service.rb spec/services/streaks/check_service_spec.rb
git commit -m "feat(services): Streaks::CheckService for milestone + threshold detection"
```

---

## Task 7: `Ui::Toast` component — write failing test

**Files:**
- Test: `spec/components/ui/toast_component_spec.rb`

- [ ] **Step 1: Write failing test**

Write to `spec/components/ui/toast_component_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe Ui::Toast::Component, type: :component do
  it 'renders a default toast with the given message' do
    render_inline(described_class.new(message: 'Saved'))
    expect(page).to have_css('[data-fx-event="toast"]', text: 'Saved')
  end

  it 'supports variant: :success' do
    render_inline(described_class.new(message: 'Done!', variant: :success))
    expect(page).to have_css('[data-fx-event="toast"][data-fx-variant="success"]', text: 'Done!')
  end

  it 'supports variant: :error' do
    render_inline(described_class.new(message: 'Oops', variant: :error))
    expect(page).to have_css('[data-fx-event="toast"][data-fx-variant="error"]', text: 'Oops')
  end

  it 'sets auto-dismiss attribute (default 3000ms)' do
    render_inline(described_class.new(message: 'Hi'))
    expect(page).to have_css('[data-fx-dismiss-after="3000"]')
  end

  it 'allows custom dismiss duration' do
    render_inline(described_class.new(message: 'Hi', dismiss_after: 5000))
    expect(page).to have_css('[data-fx-dismiss-after="5000"]')
  end
end
```

- [ ] **Step 2: Run test — verify failure**

Run: `docker compose exec web bundle exec rspec spec/components/ui/toast_component_spec.rb`
Expected: FAIL with `uninitialized constant Ui::Toast`.

---

## Task 8: `Ui::Toast` component — implement

**Files:**
- Create: `app/components/ui/toast/component.rb`
- Create: `app/components/ui/toast/component.html.erb`

- [ ] **Step 1: Implement component class**

Write to `app/components/ui/toast/component.rb`:

```ruby
module Ui
  module Toast
    class Component < ApplicationComponent
      VARIANTS = %i[default success error info].freeze

      def initialize(message:, variant: :default, dismiss_after: 3000, **options)
        @message = message
        @variant = VARIANTS.include?(variant.to_sym) ? variant.to_sym : :default
        @dismiss_after = dismiss_after.to_i
        @options = options
        super()
      end

      attr_reader :message, :variant, :dismiss_after

      def variant_classes
        case variant
        when :success then 'bg-emerald-500 text-white'
        when :error   then 'bg-rose-500 text-white'
        when :info    then 'bg-sky-500 text-white'
        else 'bg-foreground text-bg'
        end
      end
    end
  end
end
```

- [ ] **Step 2: Implement template**

Write to `app/components/ui/toast/component.html.erb`:

```erb
<div
  class="anim-fade-up shadow-card rounded-card px-4 py-3 font-bold flex items-center gap-2 <%= variant_classes %>"
  data-fx-event="toast"
  data-fx-variant="<%= variant %>"
  data-fx-dismiss-after="<%= dismiss_after %>"
  role="status"
  aria-live="polite"
>
  <span><%= message %></span>
</div>
```

- [ ] **Step 3: Run tests — verify pass**

Run: `docker compose exec web bundle exec rspec spec/components/ui/toast_component_spec.rb`
Expected: 5 examples, 0 failures.

- [ ] **Step 4: Commit**

```bash
git add app/components/ui/toast/ spec/components/ui/toast_component_spec.rb
git commit -m "feat(ui): Ui::Toast component with variants + auto-dismiss"
```

---

## Task 9: `Ui::Modal` `variant:` arg — extend test

**Files:**
- Modify: `spec/components/ui/modal_component_spec.rb` (or create if missing)

- [ ] **Step 1: Check if spec exists**

Run: `ls spec/components/ui/modal_component_spec.rb 2>/dev/null && echo EXISTS || echo MISSING`

- [ ] **Step 2: If MISSING, create it**

Write to `spec/components/ui/modal_component_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe Ui::Modal::Component, type: :component do
  it 'renders default variant' do
    render_inline(described_class.new(title: 'Hello'))
    expect(page).to have_css('.modal-overlay')
  end

  it 'accepts variant: :success and applies success class' do
    render_inline(described_class.new(title: 'Done', variant: :success))
    expect(page).to have_css('[data-modal-variant="success"]')
  end

  it 'accepts variant: :confirm-destructive' do
    render_inline(described_class.new(title: 'Delete?', variant: :"confirm-destructive"))
    expect(page).to have_css('[data-modal-variant="confirm-destructive"]')
  end

  it 'accepts variant: :celebration and includes confetti layer' do
    render_inline(described_class.new(title: 'Yay!', variant: :celebration))
    expect(page).to have_css('[data-modal-variant="celebration"]')
    expect(page).to have_css('[data-fx-event="celebrate"][data-fx-tier="big"]')
  end

  it 'celebration variant includes auto-dismiss attr (2500ms)' do
    render_inline(described_class.new(title: 'Yay!', variant: :celebration))
    expect(page).to have_css('[data-fx-dismiss-after="2500"]')
  end

  it 'invalid variant falls back to :default' do
    render_inline(described_class.new(title: 'X', variant: :wat))
    expect(page).to have_css('[data-modal-variant="default"]')
  end
end
```

- [ ] **Step 3: Run test — verify failure**

Run: `docker compose exec web bundle exec rspec spec/components/ui/modal_component_spec.rb`
Expected: FAIL — variant arg not supported yet.

---

## Task 10: `Ui::Modal` `variant:` arg — implement

**Files:**
- Modify: `app/components/ui/modal/component.rb`
- Modify: `app/components/ui/modal/component.yml`

- [ ] **Step 1: Update component class**

Replace `app/components/ui/modal/component.rb` with:

```ruby
class Ui::Modal::Component < ApplicationComponent
  VARIANTS = %i[default success confirm-destructive celebration].freeze

  def initialize(title: nil, subtitle: nil, size: "md", id: nil, variant: :default, **options)
    @title = title
    @subtitle = subtitle
    @size = size
    @id = id
    @variant = VARIANTS.include?(variant.to_sym) ? variant.to_sym : :default
    @options = options
  end

  def call
    overlay_classes = "modal-overlay fixed inset-0 bg-black/40 backdrop-blur-sm z-[100] flex items-center justify-center p-4"
    modal_classes = "bg-surface rounded-card shadow-card w-full anim-pop-in overflow-hidden #{variant_band_class}"

    size_classes = case @size
    when "sm" then "max-w-md"
    when "lg" then "max-w-4xl"
    else "max-w-2xl"
    end

    overlay_data = {
      controller: "ui-modal",
      action: "click->ui-modal#closeOnOverlay",
      modal_variant: @variant.to_s
    }

    if @variant == :celebration
      overlay_data[:fx_event] = "celebrate"
      overlay_data[:fx_tier] = "big"
      overlay_data[:fx_dismiss_after] = "2500"
    end

    content_tag :div, class: overlay_classes, style: "display: none;", data: overlay_data, id: @id do
      content_tag :div, class: class_names(modal_classes, size_classes, @options[:class]) do
        concat header if @title || @subtitle
        concat content_tag(:div, content, class: "p-6")
      end
    end
  end

  private

  def variant_band_class
    case @variant
    when :success then "border-t-4 border-emerald-400"
    when :"confirm-destructive" then "border-t-4 border-rose-500"
    when :celebration then "border-t-4 border-accent-gold"
    else ""
    end
  end

  def header
    render Ui::TopBar::Component.new(title: @title, subtitle: @subtitle) do |c|
      c.with_right_slot do
        render Ui::Btn::Component.new(variant: "ghost", size: "icon", data: { action: "click->ui-modal#close" }) do
          render Ui::Icon::Component.new("close", size: 20)
        end
      end
    end
  end
end
```

- [ ] **Step 2: Update component.yml docs**

Read `app/components/ui/modal/component.yml`. Add `variant` arg description block matching existing arg style. Document values: `default`, `success`, `confirm-destructive`, `celebration`.

- [ ] **Step 3: Run tests — verify pass**

Run: `docker compose exec web bundle exec rspec spec/components/ui/modal_component_spec.rb`
Expected: 6 examples, 0 failures.

- [ ] **Step 4: Verify `border-accent-gold` token exists**

Run: `docker compose exec web grep -r 'accent-gold\|--accent-gold' app/assets/stylesheets/`
Expected: token exists. If MISSING — substitute with closest existing gold token (e.g. `border-yellow-400`) and update component.

- [ ] **Step 5: Commit**

```bash
git add app/components/ui/modal/component.rb app/components/ui/modal/component.yml spec/components/ui/modal_component_spec.rb
git commit -m "feat(ui): Ui::Modal variant arg (success/confirm-destructive/celebration)"
```

---

## Task 11: Celebration partial + fx_stage container

**Files:**
- Create: `app/views/kid/shared/_celebration.html.erb`
- Create: `app/views/kid/shared/_fx_stage.html.erb`

- [ ] **Step 1: Create `_fx_stage.html.erb`**

Write to `app/views/kid/shared/_fx_stage.html.erb`:

```erb
<%= turbo_stream_from "kid_#{current_profile.id}" if current_profile %>
<div id="fx_stage" class="contents"></div>
<div id="fx_confetti_layer" class="confetti-layer pointer-events-none fixed inset-0 z-[200]" style="display:none"></div>
```

- [ ] **Step 2: Create `_celebration.html.erb`**

Write to `app/views/kid/shared/_celebration.html.erb`:

```erb
<%# locals: (tier:, payload:) %>
<div
  id="celebration_<%= (Time.current.to_f * 1000).to_i %>"
  data-fx-event="celebrate"
  data-fx-tier="<%= tier %>"
  data-fx-payload="<%= payload.to_json %>"
  class="anim-pop-in"
>
  <% if tier.to_sym == :big %>
    <%= render Ui::Modal::Component.new(title: payload[:message] || "Conquista!", variant: :celebration, id: "celebration_modal_#{(Time.current.to_f * 1000).to_i}") do %>
      <div class="text-center py-4">
        <% if payload[:points] %>
          <p class="text-3xl font-display font-extrabold text-accent-gold">+<%= payload[:points] %> ★</p>
        <% end %>
        <% if payload[:reward_title] %>
          <p class="mt-2 text-lg font-bold"><%= payload[:reward_title] %></p>
        <% end %>
        <% if payload[:days] %>
          <p class="mt-2 text-lg font-bold"><%= payload[:days] %> dias seguidos! 🔥</p>
        <% end %>
        <% if payload[:threshold] %>
          <p class="mt-2 text-lg font-bold">Você passou de <%= payload[:threshold] %> ★!</p>
        <% end %>
      </div>
    <% end %>
  <% else %>
    <%= render Ui::Toast::Component.new(message: payload[:message] || "✨", variant: :info) %>
  <% end %>
</div>
```

- [ ] **Step 3: Mount `_fx_stage` in kid layout**

Edit `app/views/layouts/kid.html.erb` — add `data-controller="fx"` to `<body>` and render fx_stage before `<main>`.

Replace lines 9-23 with:

```erb
  <body class="min-h-screen bg-bg-deep overflow-x-hidden" data-palette="<%= palette_for(current_profile) %>" data-controller="fx">
    <div data-controller="switch-profile" class="absolute top-4 right-4 z-20">
      <%= form_with url: profile_session_path, method: :delete, local: true,
                    data: { switch_profile_target: "form" } do %>
        <button type="button" data-action="click->switch-profile#confirm"
                class="text-sm font-bold text-muted-foreground hover:text-primary">
          Trocar perfil
        </button>
      <% end %>
    </div>
    <%= render "shared/kid_nav" %>
    <%= render "kid/shared/fx_stage" %>
    <main class="p-6 w-full max-w-screen-md mx-auto pb-24 md:pb-10">
      <%= render Ui::Flash::Component.new %>
      <%= yield %>
    </main>
  </body>
```

- [ ] **Step 4: Verify Rails boots**

Run: `docker compose exec web bin/rails runner "puts 'ok'"`
Expected: `ok` printed.

- [ ] **Step 5: Commit**

```bash
git add app/views/kid/shared/_celebration.html.erb app/views/kid/shared/_fx_stage.html.erb app/views/layouts/kid.html.erb
git commit -m "feat(ui): celebration partial + fx_stage broadcast container in kid layout"
```

---

## Task 12: `fx_controller.js` — Stimulus FX dispatcher

**Files:**
- Create: `app/assets/controllers/fx_controller.js`

- [ ] **Step 1: Implement controller**

Write to `app/assets/controllers/fx_controller.js`:

```javascript
// fx_controller.js — single FX dispatcher for the kid app
// Mounted on <body data-controller="fx">. Observes the DOM for nodes
// carrying data-fx-event and dispatches to the matching handler.
//
// Contract:
//   data-fx-event="<name>"           required
//   data-fx-tier="big|small"         optional (celebrate)
//   data-fx-payload="{...JSON}"      optional
//   data-fx-dismiss-after="<ms>"     optional auto-dismiss
//
// Re-fire guard: data-fx-fired="true" set after first run.

import { Controller } from "@hotwired/stimulus"
import { animate } from "motion"
import confetti from "canvas-confetti"

export default class extends Controller {
  connect() {
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this._lastBurstAt = 0
    this._queue = []
    this._processing = false

    // Process nodes already in DOM
    this.scan(this.element)

    // Watch for new nodes
    this.observer = new MutationObserver((mutations) => {
      for (const m of mutations) {
        for (const node of m.addedNodes) {
          if (node.nodeType !== 1) continue
          this.scan(node)
        }
      }
    })
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  scan(root) {
    const nodes = []
    if (root.matches?.("[data-fx-event]")) nodes.push(root)
    nodes.push(...root.querySelectorAll?.("[data-fx-event]") || [])
    for (const node of nodes) {
      if (node.dataset.fxFired === "true") continue
      this.enqueue(node)
    }
  }

  enqueue(node) {
    this._queue.push(node)
    if (!this._processing) this.drain()
  }

  async drain() {
    this._processing = true
    while (this._queue.length) {
      const node = this._queue.shift()
      await this.dispatch(node)
      // 200ms gap between sequenced FX
      await new Promise((r) => setTimeout(r, 200))
    }
    this._processing = false
  }

  async dispatch(node) {
    node.dataset.fxFired = "true"
    if (this.reducedMotion) node.dataset.fxFiredReduced = "true"

    const event = node.dataset.fxEvent
    const tier = node.dataset.fxTier || "small"
    const payload = this.parsePayload(node.dataset.fxPayload)
    const dismissAfter = parseInt(node.dataset.fxDismissAfter || "0", 10)

    switch (event) {
      case "celebrate":
        await this.celebrate(node, tier, payload)
        break
      case "shake":
        this.shake(node)
        break
      case "pop-in":
        this.popIn(node)
        break
      case "toast":
        // Toast self-renders via CSS; only handle auto-dismiss
        break
      default:
        break
    }

    if (dismissAfter > 0) {
      setTimeout(() => this.dismiss(node), dismissAfter)
    }
  }

  async celebrate(node, tier, payload) {
    if (tier === "big") {
      this.confettiBurst(payload)
      // Open the modal inside the celebration partial if present
      const overlay = node.querySelector(".modal-overlay")
      if (overlay) overlay.style.display = "flex"
    } else {
      // small tier: pulse the node
      if (!this.reducedMotion) {
        node.classList.add("anim-pulse-once")
      }
    }
  }

  confettiBurst(payload) {
    if (this.reducedMotion) return
    const now = Date.now()
    if (now - this._lastBurstAt < 500) return
    this._lastBurstAt = now

    const colors = payload?.palette === "gold"
      ? ["#ffc41a", "#ffd96a", "#ffeaa0"]
      : ["#ffc41a", "#ff8a5c", "#ff5a8a", "#3ed49e", "#38b6ff", "#9b7aff"]

    confetti({
      particleCount: 80,
      spread: 90,
      origin: { y: 0.4 },
      colors,
      disableForReducedMotion: true,
    })
  }

  shake(node) {
    if (this.reducedMotion) return
    node.classList.remove("anim-shake")
    void node.offsetWidth // force reflow so animation re-runs
    node.classList.add("anim-shake")
  }

  popIn(node) {
    if (this.reducedMotion) return
    animate(node, { opacity: [0, 1], transform: ["scale(0.94)", "scale(1)"] }, { duration: 0.38, easing: [0.34, 1.56, 0.64, 1] })
  }

  dismiss(node) {
    const overlay = node.querySelector?.(".modal-overlay")
    if (overlay) overlay.style.display = "none"
    if (this.reducedMotion) {
      node.remove()
      return
    }
    animate(node, { opacity: [1, 0] }, { duration: 0.2 }).finished.then(() => node.remove())
  }

  parsePayload(raw) {
    if (!raw) return {}
    try { return JSON.parse(raw) } catch { return {} }
  }
}
```

- [ ] **Step 2: Verify Vite picks it up**

Run: `docker compose exec web bin/vite build 2>&1 | tail -20`
Expected: success — bundle includes `motion` and `canvas-confetti`.

- [ ] **Step 3: Commit**

```bash
git add app/assets/controllers/fx_controller.js
git commit -m "feat(js): fx_controller — Stimulus FX dispatcher (Motion One + canvas-confetti)"
```

---

## Task 13: Wire `Tasks::ApproveService` to broadcast celebration

**Files:**
- Modify: `app/services/tasks/approve_service.rb`
- Modify: `spec/services/tasks/approve_service_spec.rb`

- [ ] **Step 1: Extend the spec — write failing test**

Append to `spec/services/tasks/approve_service_spec.rb` inside the `describe '#call'` block (after existing context):

```ruby
context 'celebration broadcast' do
  it 'broadcasts a celebration partial with data-fx-event and tier=big' do
    expect {
      described_class.new(profile_task).call
    }.to have_broadcasted_to("kid_#{child.id}")
      .from_channel(Turbo::StreamsChannel)
      .with { |stream| expect(stream).to include('data-fx-event="celebrate"', 'data-fx-tier="big"') }
  end

  it 'upgrades tier to :streak when Streaks::CheckService returns one' do
    allow(Streaks::CheckService).to receive(:call).and_return({ tier: :streak, payload: { days: 3 } })
    expect {
      described_class.new(profile_task).call
    }.to have_broadcasted_to("kid_#{child.id}")
      .with { |stream| expect(stream).to include('"days":3') }
  end
end
```

Note: requires `gem 'rspec-rails'` matchers + `Turbo::Test` helper. If not loaded, add to `spec/rails_helper.rb`:

```ruby
require 'turbo/test'
RSpec.configure do |c|
  c.include Turbo::Broadcastable::TestHelper
end
```

- [ ] **Step 2: Run test — verify failure**

Run: `docker compose exec web bundle exec rspec spec/services/tasks/approve_service_spec.rb`
Expected: FAIL — no broadcast happens yet.

- [ ] **Step 3: Implement broadcast**

Replace `app/services/tasks/approve_service.rb` with:

```ruby
module Tasks
  class ApproveService < ApplicationService
    def initialize(profile_task)
      @profile_task = profile_task
      @profile = profile_task.profile
    end

    def call
      Rails.logger.info("[Tasks::ApproveService] start profile_task_id=#{@profile_task.id}")

      unless @profile_task.awaiting_approval?
        Rails.logger.info("[Tasks::ApproveService] failure not awaiting_approval id=#{@profile_task.id}")
        return fail_with("Tarefa não está aguardando aprovação")
      end

      points_before = @profile.points
      points_after = nil

      ActiveRecord::Base.transaction do
        @profile_task.update!(status: :approved, completed_at: Time.current)
        @profile.increment!(:points, @profile_task.points)

        ActivityLog.create!(
          profile: @profile,
          log_type: :earn,
          title: "Missão Concluída: #{@profile_task.title}",
          points: @profile_task.points
        )
      end

      points_after = @profile.reload.points
      broadcast_celebration(points_before: points_before, points_after: points_after)

      Rails.logger.info("[Tasks::ApproveService] success id=#{@profile_task.id}")
      ok(@profile_task)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Tasks::ApproveService] exception id=#{@profile_task.id} error=#{e.message}")
      fail_with(e.message)
    end

    private

    def broadcast_celebration(points_before:, points_after:)
      tier = Ui::Celebration.tier_for(:approved)
      payload = { points: @profile_task.points, message: "Tarefa aprovada!" }

      override = Streaks::CheckService.call(@profile, points_before: points_before, points_after: points_after)
      if override
        tier = override[:tier]
        payload = payload.merge(override[:payload])
      end

      Turbo::StreamsChannel.broadcast_append_to(
        "kid_#{@profile.id}",
        target: "fx_stage",
        partial: "kid/shared/celebration",
        locals: { tier: tier, payload: payload }
      )
    rescue StandardError => e
      Rails.logger.warn("[Tasks::ApproveService] broadcast failed id=#{@profile_task.id} error=#{e.message}")
    end
  end
end
```

- [ ] **Step 4: Run tests — verify pass**

Run: `docker compose exec web bundle exec rspec spec/services/tasks/approve_service_spec.rb`
Expected: all pass (existing + 2 new).

- [ ] **Step 5: Commit**

```bash
git add app/services/tasks/approve_service.rb spec/services/tasks/approve_service_spec.rb spec/rails_helper.rb
git commit -m "feat(services): ApproveService broadcasts celebration partial with tier"
```

---

## Task 14: Wire `Rewards::RedeemService` to broadcast celebration

**Files:**
- Modify: `app/services/rewards/redeem_service.rb`
- Modify: `spec/services/rewards/redeem_service_spec.rb`

- [ ] **Step 1: Read existing spec**

Run: `cat spec/services/rewards/redeem_service_spec.rb | head -30` — note the `let` setup (family, profile, reward).

- [ ] **Step 2: Write failing test**

Append inside the success-path context of `spec/services/rewards/redeem_service_spec.rb`:

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

(Adapt `child` / `reward` names to whatever the existing spec uses.)

- [ ] **Step 3: Run test — verify failure**

Run: `docker compose exec web bundle exec rspec spec/services/rewards/redeem_service_spec.rb`
Expected: FAIL — no broadcast.

- [ ] **Step 4: Implement broadcast**

Read `app/services/rewards/redeem_service.rb` in full first. Then add — at the end of the success path (after the redemption is created, outside the transaction), insert:

```ruby
broadcast_celebration(redemption) if redemption
```

And add the private method at the bottom of the class:

```ruby
private

def broadcast_celebration(redemption)
  tier = Ui::Celebration.tier_for(:redeemed)
  payload = {
    points: -@reward.cost,
    message: "Recompensa solicitada!",
    reward_title: @reward.title,
    palette: "gold"
  }

  Turbo::StreamsChannel.broadcast_append_to(
    "kid_#{@profile.id}",
    target: "fx_stage",
    partial: "kid/shared/celebration",
    locals: { tier: tier, payload: payload }
  )
rescue StandardError => e
  Rails.logger.warn("[Rewards::RedeemService] broadcast failed reward_id=#{@reward.id} error=#{e.message}")
end
```

- [ ] **Step 5: Run tests — verify pass**

Run: `docker compose exec web bundle exec rspec spec/services/rewards/redeem_service_spec.rb`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add app/services/rewards/redeem_service.rb spec/services/rewards/redeem_service_spec.rb
git commit -m "feat(services): RedeemService broadcasts gold celebration partial"
```

---

## Task 15: Wire `Tasks::CompleteService` for "all daily missions cleared"

**Files:**
- Modify: `app/services/tasks/complete_service.rb`

- [ ] **Step 1: Read existing service in full**

Run: `cat app/services/tasks/complete_service.rb`

- [ ] **Step 2: Add detection + broadcast**

After the `update!(status: :awaiting_approval)` line and the existing auto-approve block, add (still inside transaction OR after — your choice; broadcasts safe outside):

```ruby
# After commit, check if this was the last pending task today for this profile
if last_pending_task_for_today?
  broadcast_all_cleared
end
```

And at the bottom of the class add:

```ruby
private

def last_pending_task_for_today?
  # Run AFTER status flip — count remaining pending tasks for this profile today.
  remaining = @profile_task.profile
                          .profile_tasks
                          .where(status: :pending)
                          .where('created_at >= ?', Date.current.beginning_of_day)
                          .count
  remaining.zero?
end

def broadcast_all_cleared
  tier = Ui::Celebration.tier_for(:all_cleared)
  payload = { message: "Todas as missões de hoje! 🎉" }
  Turbo::StreamsChannel.broadcast_append_to(
    "kid_#{@profile_task.profile.id}",
    target: "fx_stage",
    partial: "kid/shared/celebration",
    locals: { tier: tier, payload: payload }
  )
rescue StandardError => e
  Rails.logger.warn("[Tasks::CompleteService] broadcast failed id=#{@profile_task.id} error=#{e.message}")
end
```

(If the service already has a `private` block, merge there.)

- [ ] **Step 3: Run existing complete service spec (if any)**

Run: `docker compose exec web bundle exec rspec spec/services/tasks/complete_service_spec.rb 2>&1 | tail -10`
Expected: existing tests pass. (No new test — manual smoke covers all-cleared per spec.)

- [ ] **Step 4: Commit**

```bash
git add app/services/tasks/complete_service.rb
git commit -m "feat(services): CompleteService broadcasts BIG celebration on all-cleared"
```

---

## Task 16: `BalanceChip` ID stamping for broadcast targeting

**Files:**
- Modify: `app/components/ui/balance_chip/component.rb`
- Modify: `app/views/kid/wallet/_day_groups.html.erb` (or wherever chip is rendered with id)

- [ ] **Step 1: Find chip renders**

Run: `grep -rn 'BalanceChip' app/views/ app/components/`

- [ ] **Step 2: Update component to default id when profile passed**

Modify `app/components/ui/balance_chip/component.rb` `initialize` to accept `profile:` and set default id:

```ruby
def initialize(value:, size: "md", profile: nil, **options)
  @value = value.to_i
  @size = size.to_s
  @profile = profile
  @options = options
  @options[:id] ||= "balance_chip_#{profile.id}" if profile
  super()
end
```

(Then in `call`, `@options.delete(:id)` already used.)

- [ ] **Step 3: Update one render site to pass profile**

For each spot rendering BalanceChip for the current kid, change:

```erb
<%= render Ui::BalanceChip::Component.new(value: current_profile.points) %>
```

to:

```erb
<%= render Ui::BalanceChip::Component.new(value: current_profile.points, profile: current_profile) %>
```

- [ ] **Step 4: Verify Rails boots + balance chip page renders**

Run: `docker compose exec web bin/rails runner "puts Ui::BalanceChip::Component.new(value: 5).call.length"`
Expected: prints integer (HTML length). No crash.

- [ ] **Step 5: Commit**

```bash
git add app/components/ui/balance_chip/component.rb app/views/kid/
git commit -m "feat(ui): BalanceChip stamps id=balance_chip_<profile_id> for broadcasts"
```

---

## Task 17: Replace old `celebration_controller` mounts

**Files:**
- Delete: `app/assets/controllers/celebration_controller.js`
- Modify: any view referencing `data-controller="celebration"` or `data-action="celebration#burst"`

- [ ] **Step 1: Find all references**

Run: `grep -rn 'celebration#\|controller="celebration"\|celebration-target\|celebration-auto' app/`

- [ ] **Step 2: Replace with fx equivalents**

For each match:
- `data-controller="celebration"` → remove (fx controller already on body)
- `data-action="celebration#burst"` → `data-action="click->fx#confettiBurst"` (or wrap with a `data-fx-event="celebrate" data-fx-tier="big"` div if appropriate)
- `data-celebration-target="layer"` → remove (fx_controller uses `#fx_confetti_layer`)
- `data-celebration-auto-value="true"` → wrap target node with `<div data-fx-event="celebrate" data-fx-tier="big">…</div>`

For each rewritten file, verify in browser later (smoke test).

- [ ] **Step 3: Add `confettiBurst` action shortcut to fx_controller**

In `app/assets/controllers/fx_controller.js`, add a public action method (above `parsePayload`):

```javascript
confettiBurstAction(event) {
  this.confettiBurst({})
}
```

Then rename — actually use existing `confettiBurst`. Stimulus accepts kebab-case binding: `data-action="click->fx#confettiBurst"` calls `confettiBurst()`. Since current method takes a payload object, accept event:

```javascript
confettiBurst(payloadOrEvent = {}) {
  const payload = payloadOrEvent?.target ? {} : payloadOrEvent
  if (this.reducedMotion) return
  const now = Date.now()
  if (now - this._lastBurstAt < 500) return
  this._lastBurstAt = now
  const colors = payload?.palette === "gold"
    ? ["#ffc41a", "#ffd96a", "#ffeaa0"]
    : ["#ffc41a", "#ff8a5c", "#ff5a8a", "#3ed49e", "#38b6ff", "#9b7aff"]
  confetti({
    particleCount: 80,
    spread: 90,
    origin: { y: 0.4 },
    colors,
    disableForReducedMotion: true,
  })
}
```

- [ ] **Step 4: Delete old controller**

```bash
git rm app/assets/controllers/celebration_controller.js
```

- [ ] **Step 5: Verify no orphan references**

Run: `grep -rn 'celebration#\|controller="celebration"' app/`
Expected: no output.

- [ ] **Step 6: Run full RSpec suite**

Run: `docker compose exec web bundle exec rspec`
Expected: green.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "refactor(js): retire celebration_controller — fx_controller covers it"
```

---

## Task 18: Apply `.anim-press` + `.anim-tile` to kid components

**Files:**
- Modify: `app/components/ui/btn/component.rb` (or template) — add `anim-press` to base classes
- Modify: `app/components/ui/mission_card/component.html.erb` — add `anim-tile` to root
- Modify: `app/components/ui/reward_tile/component.html.erb` — add `anim-tile`
- Modify: `app/components/ui/reward_catalog_card/component.html.erb` — add `anim-tile`
- Modify: `app/components/ui/featured_reward_card/component.html.erb` — add `anim-tile`

- [ ] **Step 1: Find btn class definition**

Run: `cat app/components/ui/btn/component.rb`

- [ ] **Step 2: Add `anim-press` to btn base classes**

Locate the line building `base_classes` (or equivalent). Append `' anim-press'` to the class string. Apply to all variants — buttons should always feel the press.

- [ ] **Step 3: Add `anim-tile` to each card template**

For each ERB above, add `anim-tile` to the outermost element's class list. Example:

```erb
<%# was: %>
<div class="bg-white rounded-card shadow-card p-4">
<%# becomes: %>
<div class="bg-white rounded-card shadow-card p-4 anim-tile">
```

- [ ] **Step 4: Verify build**

Run: `docker compose exec web bin/vite build 2>&1 | tail -5`
Expected: success.

- [ ] **Step 5: Run component specs**

Run: `docker compose exec web bundle exec rspec spec/components/`
Expected: green.

- [ ] **Step 6: Commit**

```bash
git add app/components/ui/btn/ app/components/ui/mission_card/ app/components/ui/reward_tile/ app/components/ui/reward_catalog_card/ app/components/ui/featured_reward_card/
git commit -m "feat(ui): apply anim-press + anim-tile across kid card components"
```

---

## Task 19: Lint + final test sweep

**Files:** —

- [ ] **Step 1: Run rubocop**

Run: `docker compose exec web bin/rubocop -a`
Expected: clean (or autocorrected). Review the diff before committing.

- [ ] **Step 2: Run brakeman**

Run: `docker compose exec web bin/brakeman -q`
Expected: no new warnings.

- [ ] **Step 3: Run full suite**

Run: `docker compose exec web bundle exec rspec`
Expected: all green.

- [ ] **Step 4: Run vite build**

Run: `docker compose exec web bin/vite build`
Expected: success.

- [ ] **Step 5: Commit lint fixes (if any)**

```bash
git add -A
git commit -m "chore: rubocop autocorrect post-FX layer"
```

(Skip if no diff.)

---

## Task 20: Manual smoke checklist

**Files:** —

Run `bin/dev`, open kid app in browser. Check each item:

- [ ] Tap "Done" on a mission → button presses (scale .96), tile pulses, toast appears "Aguardando aprovação ✨"
- [ ] As parent (second tab/profile), approve the task → kid tab shows: confetti burst + celebration modal + balance count-up
- [ ] Redeem a reward → gold-only confetti + celebration modal with reward title
- [ ] Force a streak: create earn ActivityLogs for 3 consecutive days for one kid (rails console), then approve a task → modal shows "3 dias seguidos! 🔥"
- [ ] Force a threshold: set kid points to 49, approve task worth 5 → modal shows "Você passou de 50 ★!"
- [ ] Complete the last pending task of the day → BIG "Todas as missões de hoje! 🎉" celebration
- [ ] Trigger two BIG events fast (approve + redeem within 500ms) → queue serializes (200ms gap, single confetti burst)
- [ ] Fire 5 toasts via console (`document.querySelectorAll(...)` injection) → max 3 visible (TODO if stack-cap not implemented yet — log as known gap)
- [ ] System Settings → enable Reduce Motion → re-trigger an approval → modal opens, balance updates, **no confetti**, no animation entry
- [ ] Mobile (Chrome DevTools mobile emulation) → tap responsiveness feels natural, no jank

If any item fails, file follow-up issue (do not silently fix in this plan).

- [ ] **Final commit (if checklist file added):** None required — checklist lives in spec doc.

---

## Self-Review

Spec coverage checklist (against `2026-04-26-kid-ui-vibrancy-design.md`):

| Spec section | Plan task |
|---|---|
| Motion tokens (CSS) | Task 2 |
| FX runtime (Stimulus) | Task 12 + 17 |
| `Ui::Celebration` service | Task 3 + 4 |
| `Streaks::CheckService` | Task 5 + 6 |
| `Ui::Toast` component | Task 7 + 8 |
| `Ui::Modal` `variant:` arg | Task 9 + 10 |
| `_celebration` partial + `fx_stage` | Task 11 |
| `kid.html.erb` mount | Task 11 |
| `ApproveService` broadcast | Task 13 |
| `RedeemService` broadcast | Task 14 |
| `CompleteService` all-cleared | Task 15 |
| `BalanceChip` id stamping | Task 16 |
| Delete old `celebration_controller` | Task 17 |
| Apply `anim-press`/`anim-tile` to cards | Task 18 |
| `package.json` add `motion` | Task 1 |
| `prefers-reduced-motion` | CSS layer Task 2, JS layer Task 12 |
| Streak/threshold collision priority | Task 6 |
| Manual smoke checklist | Task 20 |

All sections covered. No placeholders. Type names consistent (`Ui::Celebration`, `Streaks::CheckService`, `fx_controller`, `Ui::Toast::Component`, `Ui::Modal::Component` `variant:`). Method signatures stable across tasks (`tier_for(event_type, **ctx)`, `Streaks::CheckService.call(profile, points_before:, points_after:)`).
