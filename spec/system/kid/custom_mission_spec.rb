require "rails_helper"

RSpec.describe "Kid custom mission flow", type: :system do
  let!(:family)   { create(:family, name: "Custom Family") }
  let!(:category) { create(:category, family: family, name: "Casa") }
  let!(:parent)   { create(:profile, :parent, family: family, name: "Mae") }
  let!(:kid)      { create(:profile, :child,  family: family, name: "Ana", points: 0) }

  it "kid proposes a mission, parent adjusts points and approves" do
    # 1. Kid opens "+ Nova missão" form and submits a custom mission
    sign_in_as_child(kid)

    expect(page).to have_content("Bora pegar mais")
    click_on "+ Nova missão"

    expect(page).to have_current_path(new_kid_mission_path)

    fill_in "O que você fez?", with: "Lavei a louça"
    fill_in "Quanto vale?", with: "50"
    select "Casa", from: "Categoria"
    fill_in "Recado pros pais (opcional)", with: "Foi pesado"
    click_on "Enviar pra aprovação"

    expect(page).to have_content("Missão enviada para aprovação")

    # Sanity check: the custom ProfileTask got persisted
    custom_task = ProfileTask.where(profile: kid, source: :custom).last
    expect(custom_task).to be_present
    expect(custom_task.title).to eq("Lavei a louça")
    expect(custom_task.points).to eq(50)
    expect(custom_task.submission_comment).to eq("Foi pesado")
    expect(custom_task.status).to eq("awaiting_approval")

    # 2. Parent sees mission in approval queue with custom badge + comment
    sign_in_as_parent(parent)
    expect(page).to have_content("Olá, Mae", wait: 10)
    visit parent_approvals_path

    expect(page).to have_content("Lavei a louça")
    # Badge is uppercased via CSS (text-transform); match case-insensitively.
    expect(page).to have_content(/sugerida pela criança/i)
    expect(page).to have_content("Foi pesado")

    # 3. Parent overrides the points (50 → 30) and approves
    fill_in "points_override", with: "30"
    click_on "Aprovar"

    # Approve uses turbo_stream — the flash banner shows "Tarefa aprovada!" (not the redirect notice).
    expect(page).to have_content(/tarefa aprovada/i, wait: 10)

    expect(kid.reload.points).to eq(30)

    log = ActivityLog.where(profile: kid).order(:id).last
    expect(log.points).to eq(30)
    expect(log.title).to include("Lavei a louça")
    expect(log.title).to include("Sugerida pela criança")
  end
end
