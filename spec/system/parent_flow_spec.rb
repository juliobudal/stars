require "rails_helper"

RSpec.describe "Parent Flow", type: :system do
  let!(:family) { create(:family, name: "Teste") }
  let!(:parent) { create(:profile, :parent, family: family, name: "Papai") }

  before do
    sign_in_as_parent(parent)
    expect(page).to have_content("Olá, Papai", wait: 10)
  end

  it "permite gerenciar a família (perfis, tarefas e recompensas)" do
    # 1. Criar Filho — form labels: "Nome", submit "Salvar Perfil", page title "Novo perfil"
    visit new_parent_profile_path

    expect(page).to have_content("Novo perfil", wait: 10)
    fill_in "Nome", with: "Zezinho"
    click_on "Salvar Perfil"

    expect(page).to have_content("Filho adicionado com sucesso!", wait: 10)
    expect(page).to have_content("Zezinho")

    # 2. Criar Tarefa Global — labels: "Título", "Estrelinhas", "Frequência" (select), submit "Salvar Missão"
    visit new_parent_global_task_path

    expect(page).to have_content("Nova missão", wait: 10)
    fill_in "Título", with: "Arrumar a cama"
    fill_in "Estrelinhas", with: "50"
    select "Diária", from: "Frequência"
    click_on "Salvar Missão"

    expect(page).to have_content("Tarefa criada com sucesso.", wait: 10)
    expect(GlobalTask.exists?(title: "Arrumar a cama")).to be(true)

    # 3. Criar Recompensa — labels: "Nome da Recompensa", "Custo (⭐)", submit "Salvar Recompensa"
    visit new_parent_reward_path

    expect(page).to have_content("Nova recompensa", wait: 10)
    fill_in "Nome da Recompensa", with: "Video Game 30min"
    fill_in "Custo", with: "100"
    click_on "Salvar Recompensa"

    expect(page).to have_content("Recompensa criada com sucesso!", wait: 10)
    expect(page).to have_content("Video Game 30min")
  end
end
