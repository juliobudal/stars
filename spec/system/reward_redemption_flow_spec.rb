require "rails_helper"

RSpec.describe "Reward Redemption Flow", type: :system do
  before do
    # Cleanup in correct order
    Redemption.delete_all
    ActivityLog.delete_all
    ProfileTask.delete_all
    Reward.delete_all
    Profile.delete_all
    GlobalTask.delete_all
    Family.delete_all
    
    @family = create(:family, name: "Teste")
    @parent = create(:profile, :parent, family: @family, name: "Papai")
    @child = create(:profile, :child, family: @family, name: "Filhote", points: 500)
    @reward = create(:reward, family: @family, title: "Sorvete", cost: 300)
  end

  it "permite ao filho resgatar uma recompensa e ao pai aprovar" do
    visit root_path
    click_on "Filhote"
    
    expect(page).to have_content("Filhote")
    visit kid_rewards_path
    
    expect(page).to have_content("Sorvete")
    
    # Clique pelo ID
    find("#redeem_reward_#{@reward.id}").click

    expect(page).to have_content("Resgate solicitado!")
    expect(page).to have_content("200")

    # 2. Pai aprova
    visit root_path
    click_on "Papai"
    
    visit parent_approvals_path
    
    expect(page).to have_content("Sorvete")
    click_on "Aprovar"
    expect(page).to have_content("Resgate aprovado!")

    # 3. Verificar logs
    visit parent_activity_logs_path
    expect(page).to have_content("Solicitado: Sorvete")
  end
end
