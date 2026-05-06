require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::FormSection::Component, type: :component do
  include ViewComponent::TestHelpers

  it "wraps content in a card with hairline border + shadow" do
    render_inline(described_class.new) { "<input />".html_safe }
    section = page.find("section")
    expect(section[:class]).to include("bg-surface", "rounded-card", "border-hairline", "shadow-card")
    expect(section).to have_css("input")
  end

  it "renders the eyebrow title when provided" do
    render_inline(described_class.new(title: "Configurações")) { "x" }
    expect(page).to have_text("Configurações")
  end

  it "omits the title block when title is blank" do
    render_inline(described_class.new) { "x" }
    expect(page).not_to have_css(".uppercase")
  end

  it "merges a custom class onto the section element" do
    render_inline(described_class.new(class: "extra-class")) { "x" }
    expect(page.find("section")[:class]).to include("extra-class")
  end
end
