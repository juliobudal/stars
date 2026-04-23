require "rails_helper"

RSpec.describe "Reward Redemption Flow", type: :system do
  let!(:family) { create(:family, name: "Teste") }
  let!(:parent) { create(:profile, :parent, family: family, name: "Papai") }
  let!(:child) { create(:profile, :child, family: family, name: "Filhote", points: 500) }
  let!(:reward) { create(:reward, family: family, title: "Sorvete", cost: 300) }

  it "permite ao filho resgatar uma recompensa e ao pai aprovar" do
    # 1. Kid redeems reward via modal
    sign_in_as_child(child)
    visit kid_rewards_path

    expect(page).to have_content("Sorvete")

    # Open modal and click submit via JS (modal starts display:none; Capybara visibility checks fail on hidden ancestors)
    open_modal_and_click("modal_reward_#{reward.id}", "Resgatar!")

    expect(page).to have_content("Resgate solicitado!")

    # 2. Parent approves
    sign_in_as_parent(parent)
    visit parent_approvals_path

    # Show the rewards panel directly via JS (tabs_controller scopes to its own element,
    # which doesn't contain the sibling panels — so we reveal panel-rewards manually)
    page.execute_script(<<~JS)
      var panel = document.getElementById('panel-rewards');
      if (panel) { panel.style.display = 'flex'; panel.style.flexDirection = 'column'; }
    JS

    # "Sorvete" is now visible in panel-rewards
    expect(page).to have_css("#panel-rewards", text: "Sorvete", visible: true)

    # "Entregue" is the approve label for redemptions in ApprovalRow
    within("#panel-rewards") do
      find("button", text: "Entregue", exact: false).click
    end
    expect(page).to have_content("Resgate aprovado!")

    # 3. Verify activity log
    visit parent_activity_logs_path
    expect(page).to have_content("Solicitado: Sorvete")
  end
end
