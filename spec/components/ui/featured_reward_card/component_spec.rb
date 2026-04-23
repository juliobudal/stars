require "rails_helper"
require "view_component/test_helpers"
require "ostruct"

RSpec.describe Ui::FeaturedRewardCard::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:reward) { OpenStruct.new(title: "Passeio", cost: 50, icon: "gift") }

  it "renders title, button with cost and affordable message" do
    render_inline(described_class.new(reward: reward, balance: 60, modal_id: "modal_x"))
    expect(page).to have_text("Passeio")
    expect(page).to have_text("Trocar por ⭐ 50")
    expect(page).to have_text("✓ Você pode pegar essa!")
    expect(page).to have_css("button[data-ui-modal-id-param='modal_x']")
  end

  it "shows shortfall when balance is low" do
    render_inline(described_class.new(reward: reward, balance: 20))
    expect(page).to have_text("Faltam 30 estrelinhas")
  end
end
