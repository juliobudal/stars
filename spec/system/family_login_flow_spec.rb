require "rails_helper"

RSpec.describe "Family login flow", type: :system do
  let!(:family) { Family.create!(name: "Fam", email: "fam@example.com", password: "supersecret1234") }
  let!(:kid)    { family.profiles.create!(name: "Kid", role: :child, pin: "1234") }

  it "logs in family and lands on picker" do
    visit root_path
    expect(page).to have_current_path(new_family_session_path)

    fill_in "Email da família", with: "fam@example.com"
    fill_in "Senha", with: "supersecret1234"
    click_on "Entrar"

    expect(page).to have_current_path(new_profile_session_path)
    expect(page).to have_content("Kid")
  end
end
