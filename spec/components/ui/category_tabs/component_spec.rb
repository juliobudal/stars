require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::CategoryTabs::Component, type: :component do
  include ViewComponent::TestHelpers

  it "renders each item as a tab button" do
    render_inline(described_class.new(
      active: "a",
      items: [ { id: "a", label: "A" }, { id: "b", label: "B" } ]
    ))
    expect(page).to have_css("button[data-tabs-target='tab']", count: 2)
    expect(page).to have_css("button.active", text: "A")
  end

  it "wires Stimulus data-tabs-id-param per item" do
    render_inline(described_class.new(
      active: "a",
      items: [ { id: "x", label: "X" } ]
    ))
    expect(page).to have_css("button[data-tabs-id-param='x']")
  end

  it "renders icon when provided" do
    render_inline(described_class.new(
      active: "a",
      items: [ { id: "a", label: "A", icon: "star" } ]
    ))
    expect(page).to have_css("i.ph-star")
  end
end
