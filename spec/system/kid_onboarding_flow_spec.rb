require "rails_helper"

RSpec.describe "Kid onboarding flow", type: :system do
  let(:family) { create(:family) }
  let!(:fresh_kid) { create(:profile, :child, :fresh, family: family, name: "Lila") }

  it "walks a brand-new kid through welcome → interests → how → ready → dashboard" do
    visit new_family_session_path
    fill_in "Email da família", with: family.email
    fill_in "Senha", with: "supersecret1234"
    click_on "Entrar"

    expect(page).to have_current_path(new_profile_session_path, wait: 5)
    click_on "Lila"
    expect(page).to have_css("button.pin-key", wait: 5)
    "1234".chars.each { |d| find("button.pin-key", text: d, match: :first).click }

    expect(page).to have_current_path(kid_welcome_path, wait: 10)
    expect(page).to have_content(/lila/i)

    click_on "Bora!"
    expect(page).to have_current_path(kid_welcome_interests_path)

    %w[Dinossauros Espaço Futebol].each do |label|
      find("label", text: label).click
    end
    click_on "Próximo"

    expect(page).to have_current_path(kid_welcome_how_path)
    expect(page).to have_content(/missões/i)
    expect(page).to have_content(/estrelinhas/i)
    expect(page).to have_content(/recompensas/i)

    click_on "Entendi"
    expect(page).to have_current_path(kid_welcome_ready_path)
    expect(page).to have_content(/tudo pronto/i)

    click_on "Começar"
    expect(page).to have_current_path(kid_root_path, wait: 10)

    fresh_kid.reload
    expect(fresh_kid.onboarded_at).to be_present
    expect(fresh_kid.profile_interests.pluck(:interest_key))
      .to match_array(%w[dinossauros espaco futebol])
  end
end
