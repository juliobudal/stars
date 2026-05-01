require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::IosInstallHint::Component, type: :component do
  include ViewComponent::TestHelpers

  it "renders a hidden wrapper with the ios-install-hint controller" do
    render_inline(described_class.new)

    wrapper = page.find("div[data-controller='ios-install-hint']", visible: :all)
    expect(wrapper["hidden"]).not_to be_nil
  end

  it "includes the iOS share-flow instruction in pt-BR" do
    rendered = render_inline(described_class.new).to_html

    expect(rendered).to include("Adicionar à Tela de Início")
    expect(rendered).to include("Compartilhar")
  end

  it "renders a dismiss button wired to the dismiss action" do
    render_inline(described_class.new)

    button = page.find("button[aria-label='Fechar']", visible: :all)
    expect(button["data-action"]).to include("ios-install-hint#dismiss")
  end
end
