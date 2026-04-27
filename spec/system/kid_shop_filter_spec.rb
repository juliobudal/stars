require "rails_helper"

RSpec.describe "Kid shop category filter", type: :system do
  let!(:family) { create(:family, name: "Filtro") }
  let!(:kid) { create(:profile, :child, family: family, name: "Kiko", points: 500) }

  let!(:cat_a) { family.categories.find_by(name: "Telinha") }
  let!(:cat_b) { family.categories.find_by(name: "Docinhos") }
  let!(:reward_a) { create(:reward, family: family, category: cat_a, title: "Vídeo Game", cost: 100) }
  let!(:reward_b) { create(:reward, family: family, category: cat_b, title: "Sorvete", cost: 50) }

  before do
    sign_in_as_child(kid)
  end

  it "shows only category tabs that have rewards" do
    visit kid_rewards_path
    expect(page).to have_content(/telinha/i)
    expect(page).to have_content(/docinhos/i)
    expect(page).not_to have_content("Brinquedos")
    expect(page).not_to have_content("Outro")
  end

  it "tags each reward tile with its category id for filtering" do
    visit kid_rewards_path
    expect(page).to have_css("[data-filter-tabs-target='item'][data-panels~='#{cat_a.id}']", visible: :all)
    expect(page).to have_css("[data-filter-tabs-target='item'][data-panels~='#{cat_b.id}']", visible: :all)
  end
end
