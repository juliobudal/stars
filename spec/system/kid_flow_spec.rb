require "rails_helper"

RSpec.describe "Kid Flow", type: :system do
  let!(:family) { create(:family) }
  let!(:child) { create(:profile, :child, family: family, name: "Filhote") }
  let!(:global_task) { create(:global_task, family: family, title: "Lavar Louça", points: 100) }
  let!(:profile_task) { create(:profile_task, profile: child, global_task: global_task, status: :pending) }

  before do
    visit root_path
    find("button", text: "Filhote").click
  end

  it "permite ao filho submeter uma missão e vê-la aguardando aprovação" do
    expect(page).to have_content("Filhote")
    expect(page).to have_content("Lavar Louça")
    expect(page).to have_content("100")

    # Clicar no botão de completar
    click_on "FEITO! 🏅"

    expect(page).to have_content("Missão enviada para aprovação! 🚀")

    # Verificar se aparece na seção "Já feitas"
    within "section", text: "Já feitas" do
      expect(page).to have_content("Lavar Louça")
      expect(page).to have_content("Aguardando Aprovação...")
    end
  end
end
