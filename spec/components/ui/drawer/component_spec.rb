require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::Drawer::Component, type: :component do
  include ViewComponent::TestHelpers

  it "renders an HTML <dialog> when an id is given (sync mode)" do
    render_inline(described_class.new(id: "drawer-1", title: "Filtros")) { "body" }
    dialog = page.find("dialog#drawer-1", visible: false)
    expect(dialog).to be_present
  end

  it "uses the default size class when none specified" do
    render_inline(described_class.new(id: "drawer-2")) { "body" }
    dialog = page.find("dialog#drawer-2", visible: false)
    expect(dialog[:class]).to include("w-2xl")
  end

  it "respects an explicit size" do
    render_inline(described_class.new(id: "drawer-3", size: "xl")) { "body" }
    dialog = page.find("dialog#drawer-3", visible: false)
    expect(dialog[:class]).to include("w-xl")
  end

  it "renders a non-dialog container when no id is given (open-tab fallback)" do
    render_inline(described_class.new) { "body" }
    expect(page).to have_css("div.bg-background", visible: false)
    expect(page).not_to have_css("dialog", visible: false)
  end
end
