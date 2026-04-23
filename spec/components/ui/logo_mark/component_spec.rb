require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::LogoMark::Component, type: :component do
  include ViewComponent::TestHelpers
  include ActiveSupport::Testing::TimeHelpers

  it "renders star SVG path during day (10h)" do
    travel_to Time.zone.local(2024, 1, 1, 10, 0, 0) do
      render_inline(described_class.new)
      expect(page).to have_css("svg path[d*='M11.525 2.295']")
    end
  end

  it "renders moon-star SVG path at night (22h)" do
    travel_to Time.zone.local(2024, 1, 1, 22, 0, 0) do
      render_inline(described_class.new)
      expect(page).to have_css("svg path[d*='M20.985 12.486']")
    end
  end

  it "uses --star stroke color during day" do
    travel_to Time.zone.local(2024, 1, 1, 10, 0, 0) do
      render_inline(described_class.new)
      expect(page).to have_css("svg[stroke='var(--star)']")
    end
  end

  it "uses --primary stroke color at night" do
    travel_to Time.zone.local(2024, 1, 1, 22, 0, 0) do
      render_inline(described_class.new)
      expect(page).to have_css("svg[stroke='var(--primary)']")
    end
  end

  it "accepts custom size" do
    travel_to Time.zone.local(2024, 1, 1, 10, 0, 0) do
      render_inline(described_class.new(size: 32))
      expect(page).to have_css("svg[width='32']")
    end
  end

  # Boundary: DAY_START=6, DAY_END=20
  it "is night at hour 5 (before DAY_START)" do
    travel_to Time.zone.local(2024, 1, 1, 5, 0, 0) do
      render_inline(described_class.new)
      expect(page).to have_css("svg path[d*='M20.985 12.486']")
    end
  end

  it "is day at hour 6 (DAY_START boundary)" do
    travel_to Time.zone.local(2024, 1, 1, 6, 0, 0) do
      render_inline(described_class.new)
      expect(page).to have_css("svg path[d*='M11.525 2.295']")
    end
  end

  it "is day at hour 19 (last hour before DAY_END)" do
    travel_to Time.zone.local(2024, 1, 1, 19, 0, 0) do
      render_inline(described_class.new)
      expect(page).to have_css("svg path[d*='M11.525 2.295']")
    end
  end

  it "is night at hour 20 (DAY_END boundary)" do
    travel_to Time.zone.local(2024, 1, 1, 20, 0, 0) do
      render_inline(described_class.new)
      expect(page).to have_css("svg path[d*='M20.985 12.486']")
    end
  end
end
