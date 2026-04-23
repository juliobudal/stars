require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::FilterChips::Component, type: :component do
  include ViewComponent::TestHelpers

  it "renders each item as a tab button" do
    render_inline(described_class.new(
      active: "a",
      items: [
        { id: "a", label: "A", count: 3 },
        { id: "b", label: "B" }
      ]
    ))
    expect(page).to have_css("[role=tablist]")
    expect(page).to have_css("button.tab", count: 2)
    expect(page).to have_css("button.tab.active", count: 1)
  end

  it "marks active tab with aria-selected=true" do
    render_inline(described_class.new(
      active: "b",
      items: [ { id: "a", label: "A" }, { id: "b", label: "B" } ]
    ))
    expect(page).to have_css("button.active[aria-selected='true']", text: "B")
  end
end
