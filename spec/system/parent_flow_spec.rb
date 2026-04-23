require "rails_helper"

RSpec.describe "Parent Flow", type: :system do
  let!(:family) { create(:family, name: "Teste") }
  let!(:parent) { create(:profile, :parent, family: family, name: "Papai") }

  before do
    visit root_path
    find("button", text: "Papai").click
    expect(page).to have_content("Visão Geral", wait: 10)
  end

  it "permite gerenciar a família (perfis, tarefas e recompensas)" do
    # 1. Criar Filho (14.1)
    visit new_parent_profile_path

    expect(page).to have_content("Novo Filho(a)", wait: 10)
    fill_in "Nome do Filho", with: "Zezinho"
    fill_in "Avatar (Emoji ou Sigla)", with: "🐱"
    click_on "Salvar"

    expect(page).to have_content("Filho adicionado com sucesso!", wait: 10)
    expect(page).to have_content("Zezinho")

    # 2. Criar Tarefa Global (14.2)
    visit new_parent_global_task_path

    expect(page).to have_content("Nova Tarefa", wait: 10)
    fill_in "Título da Missão", with: "Arrumar a cama"
    fill_in "Estrelinhas (⭐)", with: "50"
    select "🏠 Casa", from: "Categoria"
    select "📅 Diária", from: "Frequência"
    check "Seg"
    click_on "Salvar Tarefa"

    expect(page).to have_content("Tarefa criada com sucesso.", wait: 10)
    expect(page).to have_content("Arrumar a cama")

    # 3. Criar Recompensa (14.3)
    visit new_parent_reward_path

    expect(page).to have_content("Nova Recompensa", wait: 10)
    fill_in "Nome da Recompensa", with: "Video Game 30min"
    fill_in "Custo em Estrelinhas (⭐)", with: "100"
    fill_in "Ícone / Emoji", with: "🎮"
    click_on "Salvar Recompensa"

    expect(page).to have_content("Recompensa criada com sucesso!", wait: 10)
    expect(page).to have_content("Video Game 30min")
  end
end
