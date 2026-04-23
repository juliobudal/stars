require "rails_helper"

RSpec.describe "Kid Flow", type: :system do
  let!(:family) { create(:family) }
  let!(:child) { create(:profile, :child, family: family, name: "Filhote") }
  let!(:global_task) { create(:global_task, family: family, title: "Lavar Louça", points: 100) }
  let!(:profile_task) { create(:profile_task, profile: child, global_task: global_task, status: :pending) }

  before do
    sign_in_as_child(child)
  end

  it "permite ao filho submeter uma missão e vê-la aguardando aprovação" do
    expect(page).to have_content("Filhote")
    expect(page).to have_content("Lavar Louça")
    expect(page).to have_content("100")

    # Open modal and click submit via JS (modal starts display:none; Capybara visibility checks fail on hidden ancestors)
    open_modal_and_click("modal_profile_task_#{profile_task.id}", "Terminei!")

    expect(page).to have_content("Missão enviada para aprovação! 🚀")

    # Verify it appears as waiting
    expect(page).to have_content("Aguardando")
  end
end
