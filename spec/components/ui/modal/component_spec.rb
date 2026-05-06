require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::Modal::Component, type: :component do
  include ViewComponent::TestHelpers

  it "renders the modal with default variant + dialog ARIA roles" do
    render_inline(described_class.new(title: "Confirmar?")) { "body" }

    overlay = page.find(".modal-overlay", visible: false)
    dialog  = page.find('[role="dialog"]', visible: false)
    expect(overlay).to be_present
    expect(dialog["aria-modal"]).to eq("true")
    expect(dialog["aria-labelledby"]).to be_present
  end

  it "renders without aria-labelledby when no title given" do
    render_inline(described_class.new) { "body" }
    dialog = page.find('[role="dialog"]', visible: false)
    expect(dialog["aria-labelledby"]).to be_blank
  end

  it "applies celebration data attributes for the celebration variant" do
    render_inline(described_class.new(variant: :celebration)) { "body" }
    overlay = page.find(".modal-overlay", visible: false)
    expect(overlay["data-fx-event"]).to eq("celebrate")
    expect(overlay["data-fx-tier"]).to eq("big")
  end

  it "uses the provided id when given" do
    render_inline(described_class.new(id: "test-modal-id")) { "body" }
    expect(page).to have_css("#test-modal-id", visible: false)
  end

  it "starts hidden via inline display:none for the show/hide controller" do
    render_inline(described_class.new) { "body" }
    overlay = page.find(".modal-overlay", visible: false)
    expect(overlay[:style]).to include("display: none")
  end
end
