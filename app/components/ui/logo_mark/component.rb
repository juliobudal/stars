class Ui::LogoMark::Component < ViewComponent::Base
  DAY_START = 6
  DAY_END   = 20

  attr_reader :size

  def initialize(size: 24)
    @size = Integer(size)
  end

  # Uses server TZ (Rails.application.config.time_zone), not user's local clock.
  def day?
    hour = Time.current.hour
    hour >= DAY_START && hour < DAY_END
  end

  def stroke_color
    day? ? "var(--star)" : "var(--primary)"
  end
end
