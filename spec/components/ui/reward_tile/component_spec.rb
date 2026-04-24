require "rails_helper"
require "view_component/test_helpers"
require "ostruct"

RSpec.describe Ui::RewardTile::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:reward) { OpenStruct.new(title: "Sorvete", cost: 10, icon: "gift") }

  it "shows TROCAR pill when affordable" do
    render_inline(described_class.new(reward: reward, balance: 20, modal_id: "modal_r1"))
    expect(page).to have_text("Sorvete")
    expect(page).to have_text("TROCAR")
    expect(page).to have_css("button[data-ui-modal-id-param='modal_r1']")
  end

  it "shows shortfall and disables when not affordable" do
    render_inline(described_class.new(reward: reward, balance: 3))
    expect(page).to have_text("faltam 7")
    expect(page).to have_css("button[disabled]")
  end

  it "renders POPULAR badge when popular" do
    render_inline(described_class.new(reward: reward, balance: 20, popular: true))
    expect(page).to have_text("POPULAR")
  end
end
