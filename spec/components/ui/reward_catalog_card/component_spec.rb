require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::RewardCatalogCard::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:family) { create(:family) }
  let(:reward) { create(:reward, family: family, title: "Sorvete", cost: 80, category: :doce) }

  it "renders title, cost and category badge" do
    render_inline(described_class.new(reward: reward))
    expect(page).to have_text("Sorvete")
    expect(page).to have_text("80")
    expect(page).to have_text("doce")
  end
end
