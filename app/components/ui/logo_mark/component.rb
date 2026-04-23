class Ui::LogoMark::Component < ViewComponent::Base
  DAY_START = 6
  DAY_END   = 20

  def initialize(size: 24)
    @size = size
  end

  def day?
    hour = Time.current.hour
    hour >= DAY_START && hour < DAY_END
  end

  def stroke_color
    day? ? "var(--star)" : "var(--primary)"
  end
end
