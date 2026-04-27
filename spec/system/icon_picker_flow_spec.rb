require "rails_helper"

RSpec.describe "Icon picker flow", type: :system do
  let!(:family) { create(:family, name: "Familia Picker") }
  let!(:parent) { create(:profile, :parent, family: family, name: "Mae") }

  before do
    sign_in_as_parent(parent)
    expect(page).to have_content("Olá, Mae", wait: 10)
  end

  it "lets a parent pick a mission icon from the catalog and persists the slug" do
    visit new_parent_global_task_path
    expect(page).to have_content("Nova missão", wait: 10)

    find("button[aria-label='Escolher ícone']").click

    expect(page).to have_css("[data-icon-picker-target='searchInput']", visible: true, wait: 5)

    find("[data-icon-picker-target='tabCatalog']").click
    find("[data-icon-picker-target='searchInput']").set("bed")

    find("[data-icon-picker-target='catalogGrid'] button[data-slug='bed-single-01']", wait: 10).click
    click_button "Confirmar"

    fill_in "Título", with: "Arrumar a cama"
    find("button[aria-label='5 estrelinhas']").click
    select "Diária", from: "Frequência"
    click_on "Salvar missão"

    expect(page).to have_content("Tarefa criada com sucesso.", wait: 10)
    expect(GlobalTask.last.icon).to eq("bed-single-01")
  end
end
