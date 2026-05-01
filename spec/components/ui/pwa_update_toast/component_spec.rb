require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::PwaUpdateToast::Component, type: :component do
  include ViewComponent::TestHelpers

  it "renders a hidden wrapper with the pwa-update controller" do
    render_inline(described_class.new)

    wrapper = page.find("div[data-controller='pwa-update']", visible: :all)
    expect(wrapper["hidden"]).not_to be_nil
  end

  it "renders the Atualizar CTA wired to the apply action" do
    render_inline(described_class.new)

    button = page.find("button", text: "Atualizar", visible: :all)
    expect(button["data-action"]).to include("pwa-update#apply")
  end

  it "renders the dismiss button wired to the dismiss action" do
    render_inline(described_class.new)

    button = page.find("button", text: "Depois", visible: :all)
    expect(button["data-action"]).to include("pwa-update#dismiss")
  end
end
