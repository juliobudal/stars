require "rails_helper"

RSpec.describe "Parent Flow", type: :system do
  let!(:family) { create(:family, name: "Teste") }
  let!(:parent) { create(:profile, :parent, family: family, name: "Papai") }

  before do
    sign_in_as_parent(parent)
    expect(page).to have_content("Olá, Papai", wait: 10)
  end

  it "permite gerenciar a família (perfis, tarefas e recompensas)" do
    # 1. Criar Filho
    visit new_parent_profile_path

    expect(page).to have_content("Nova criança", wait: 10)
    fill_in "Nome da criança", with: "Zezinho"
    fill_in "PIN (4 dígitos)", with: "1234"
    click_on "Salvar perfil"

    expect(page).to have_content("Perfil criado.", wait: 10)
    expect(page).to have_content("Zezinho")

    # 2. Criar Tarefa Global — points via star-picker (1–10), submit "Salvar missão"
    visit new_parent_global_task_path

    expect(page).to have_content("Nova missão", wait: 10)
    fill_in "Título", with: "Arrumar a cama"
    find("button[aria-label='5 estrelinhas']").click
    find("label", text: "Diária").click
    click_on "Salvar missão"

    expect(page).to have_content("Tarefa criada com sucesso.", wait: 10)
    expect(GlobalTask.exists?(title: "Arrumar a cama")).to be(true)

    # 3. Criar Recompensa — labels: "Nome do prêmio", cost field, submit "Salvar prêmio"
    visit new_parent_reward_path

    expect(page).to have_content("Novo prêmio", wait: 10)
    fill_in "Nome do prêmio", with: "Video Game 30min"
    fill_in "Quantas estrelinhas custa?", with: "100"
    click_on "Salvar prêmio"

    expect(page).to have_content("Recompensa criada com sucesso!", wait: 10)
    expect(page).to have_content("Video Game 30min")
  end
end
