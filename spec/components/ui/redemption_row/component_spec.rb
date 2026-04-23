require "rails_helper"
require "view_component/test_helpers"
require "ostruct"

RSpec.describe Ui::RedemptionRow::Component, type: :component do
  include ViewComponent::TestHelpers

  def build_redemption(status, title: "Sorvete", cost: 10)
    reward = OpenStruct.new(cost: cost, icon: "gift")
    OpenStruct.new(
      title: title,
      reward: reward,
      pending?:  status == :pending,
      approved?: status == :approved,
      rejected?: status == :rejected
    )
  end

  it "renders pending as Disponível" do
    render_inline(described_class.new(redemption: build_redemption(:pending)))
    expect(page).to have_text("Sorvete")
    expect(page).to have_text("−10 ⭐")
    expect(page).to have_text("Disponível")
  end

  it "renders approved as Aproveitado" do
    render_inline(described_class.new(redemption: build_redemption(:approved)))
    expect(page).to have_text("Aproveitado")
  end

  it "renders rejected as Recusado" do
    render_inline(described_class.new(redemption: build_redemption(:rejected)))
    expect(page).to have_text("Recusado")
  end
end
