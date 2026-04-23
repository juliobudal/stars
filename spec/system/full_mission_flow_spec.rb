require "rails_helper"

RSpec.describe "Full Mission Flow", type: :system do
  let!(:family) { create(:family, name: "Teste") }
  let!(:parent_profile) { create(:profile, :parent, family: family, name: "Papai") }
  let!(:child_profile) { create(:profile, :child, family: family, name: "Filhote", points: 0) }
  let!(:global_task) { create(:global_task, family: family, title: "Arrumar Quarto", points: 200) }
  let!(:profile_task) { create(:profile_task, profile: child_profile, global_task: global_task, status: :pending) }

  it "permite o ciclo completo de uma missão" do
    # 1. Filho submete a missão via modal
    sign_in_as_child(child_profile)

    expect(page).to have_content("Arrumar Quarto")
    # Open modal and click submit via JS (modal starts display:none; Capybara visibility checks fail on hidden ancestors)
    open_modal_and_click("modal_profile_task_#{profile_task.id}", "Terminei!")

    expect(page).to have_content("Missão enviada para aprovação! 🚀")

    # 2. Pai aprova a missão
    sign_in_as_parent(parent_profile)

    expect(page).to have_content("Olá, Papai")
    click_on "Ver aprovações →"

    expect(page).to have_content("Arrumar Quarto")
    click_on "Aprovar"
    expect(page).to have_content("Tarefa aprovada com sucesso!")

    # 3. Filho vê as estrelas
    sign_in_as_child(child_profile)
    visit kid_wallet_index_path

    expect(page).to have_content("200")
    expect(page).to have_content("Arrumar Quarto")
  end
end
