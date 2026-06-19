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
    expect(page).to have_css("button[role=tab]", count: 2)
    expect(page).to have_css("button[role=tab][aria-selected='true']", count: 1)
  end

  it "marks active tab with aria-selected=true" do
    render_inline(described_class.new(
      active: "b",
      items: [ { id: "a", label: "A" }, { id: "b", label: "B" } ]
    ))
    expect(page).to have_css("button[role=tab][aria-selected='true']", text: "B")
  end

  it "associates each tab with its panel via aria-controls in tabs mode" do
    render_inline(described_class.new(
      active: "a",
      items: [ { id: "a", label: "A" }, { id: "b", label: "B" } ]
    ))
    expect(page).to have_css("button#tab-a[role=tab][aria-controls='panel-a']")
    expect(page).to have_css("button#tab-b[role=tab][aria-controls='panel-b']")
  end

  it "renders a toggle-button group (not a tablist) in filter-tabs mode" do
    render_inline(described_class.new(
      active: "all",
      controller: "filter-tabs",
      items: [ { id: "all", label: "Tudo" }, { id: "b", label: "B" } ]
    ))
    expect(page).to have_css("[role=group]")
    expect(page).to have_no_css("[role=tablist]")
    expect(page).to have_no_css("button[role=tab]")
    expect(page).to have_css("button[aria-pressed='true']", count: 1, text: "Tudo")
    expect(page).to have_css("button[aria-pressed='false']", text: "B")
  end
end
