# frozen_string_literal: true

# Slim 4-step (or N-step) progress indicator used by the kid onboarding
# flow. Renders `total` thin segments; the first `current` segments are
# filled with the primary color and depth shadow; the rest are muted.
class Ui::ProgressSteps::Component < ApplicationComponent
  def initialize(current:, total:)
    @current = current.to_i.clamp(0, total.to_i)
    @total = total.to_i.clamp(1, 12)
  end

  def call
    content_tag :div,
                class: "flex items-center gap-1.5 mb-7",
                role: "progressbar",
                aria: { valuenow: @current, valuemin: 0, valuemax: @total } do
      safe_join(@total.times.map { |i| segment(done: (i + 1) <= @current) })
    end
  end

  private

  def segment(done:)
    base = "flex-1 h-2 rounded-full transition-colors"
    style = if done
      "background: var(--primary); box-shadow: 0 2px 0 var(--primary-2);"
    else
      "background: var(--surface-2);"
    end
    content_tag :div, "", class: base, style: style, aria: { hidden: true }
  end
end
