require "rails_helper"

RSpec.describe "Parent categories management", type: :system do
  let!(:family) { create(:family, name: "Teste") }
  let!(:parent) { create(:profile, :parent, family: family, name: "Papai") }

  before do
    sign_in_as_parent(parent)
    expect(page).to have_content("Olá, Papai", wait: 10)
  end

  it "lists default categories on the management page" do
    visit parent_categories_path
    expect(page).to have_content("Telinha")
    expect(page).to have_content("Docinhos")
    expect(page).to have_content("Brinquedos")
  end

  it "creates a new category" do
    visit new_parent_category_path
    fill_in "Nome", with: "Música"
    click_on "Salvar"
    expect(page).to have_current_path(parent_categories_path, wait: 10)
    expect(page).to have_content("Música")
  end
end
