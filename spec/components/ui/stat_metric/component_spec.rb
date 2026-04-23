require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::StatMetric::Component, type: :component do
  include ViewComponent::TestHelpers

  it "renders prefixed value and uppercase label" do
    render_inline(described_class.new(value: 12, label: "Conquistado", tint: "mint", prefix: "+"))
    expect(page).to have_css(".card")
    expect(page).to have_text("+12")
    expect(page).to have_text("Conquistado")
  end

  it "falls back to primary tint for unknown tint" do
    render_inline(described_class.new(value: 1, label: "x", tint: "bogus"))
    expect(page).to have_css(".card")
  end
end
