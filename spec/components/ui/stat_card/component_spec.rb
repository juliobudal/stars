require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::StatCard::Component, type: :component do
  include ViewComponent::TestHelpers

  it "renders value and label" do
    render_inline(described_class.new(value: 42, label: "Estrelas", icon: "star", tint: "star"))
    expect(page).to have_css(".card")
    expect(page).to have_text("42")
    expect(page).to have_text("Estrelas")
  end

  it "falls back to primary tint for unknown tint" do
    render_inline(described_class.new(value: 1, label: "x", icon: "star", tint: "bogus"))
    expect(page).to have_css(".stat-icon-tile")
  end
end
