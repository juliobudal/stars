require "rails_helper"

RSpec.describe "Full Mission Flow", type: :system do
  let!(:family) { create(:family, name: "Teste") }
  let!(:parent_profile) { create(:profile, :parent, family: family, name: "Papai") }
  let!(:child_profile) { create(:profile, :child, family: family, name: "Filhote", points: 0) }
  let!(:global_task) { create(:global_task, family: family, title: "Arrumar Quarto", points: 200) }
  let!(:profile_task) { create(:profile_task, profile: child_profile, global_task: global_task, status: :pending) }

  before do
    Profile.where.not(id: [parent_profile.id, child_profile.id]).delete_all
    Family.where.not(id: family.id).delete_all
  end

  it "permite o ciclo completo de uma missão" do
    # 1. Filho submete a missão
    visit root_path
    find("button", text: "Filhote").click
    
    expect(page).to have_content("Arrumar Quarto")
    click_on "FEITO! 🏅"
    expect(page).to have_content("Missão enviada para aprovação!")

    # 2. Pai aprova a missão
    visit root_path
    find("button", text: "Papai").click
    
    expect(page).to have_content("Aprovações")
    click_on "Aprovações"
    
    expect(page).to have_content("Arrumar Quarto")
    click_on "Aprovar"
    expect(page).to have_content("Tarefa aprovada com sucesso!")

    # 3. Filho vê as estrelas
    visit root_path
    find("button", text: "Filhote").click
    
    # Navegar para Carteira
    visit kid_wallet_index_path
    
    expect(page).to have_content("200")
    expect(page).to have_content("Missão Concluída: Arrumar Quarto")
  end
end
