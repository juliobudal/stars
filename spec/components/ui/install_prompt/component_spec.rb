require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::InstallPrompt::Component, type: :component do
  include ViewComponent::TestHelpers

  it "renders a hidden wrapper with the install-prompt controller" do
    render_inline(described_class.new)

    wrapper = page.find("div[data-controller='install-prompt']", visible: :all)
    expect(wrapper["hidden"]).not_to be_nil
  end

  it "renders the Instalar CTA wired to the install action" do
    render_inline(described_class.new)

    button = page.find("button", text: "Instalar", visible: :all)
    expect(button["data-action"]).to include("install-prompt#install")
  end

  it "renders the dismiss button wired to the dismiss action" do
    render_inline(described_class.new)

    button = page.find("button", text: "Agora não", visible: :all)
    expect(button["data-action"]).to include("install-prompt#dismiss")
  end

  it "exposes the install button as a Stimulus target" do
    render_inline(described_class.new)
    expect(page).to have_selector("[data-install-prompt-target='installButton']", visible: :all)
  end
end
