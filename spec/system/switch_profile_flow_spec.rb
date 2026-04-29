require "rails_helper"

RSpec.describe "Switch profile flow", type: :system, js: true do
  let!(:family) { Family.create!(name: "Fam", email: "fam@example.com", password: "supersecret1234") }
  let!(:kid)    { family.profiles.create!(name: "Lila", role: :child, pin: "1234") }
  let!(:other)  { family.profiles.create!(name: "Theo", role: :child, pin: "5678") }

  it "returns to picker, family cookie intact" do
    sign_in_profile(kid, pin: "1234")
    expect(page).to have_current_path(kid_root_path, ignore_query: true)

    find("button[aria-label='Sair']").click

    expect(page).to have_current_path(new_profile_session_path)
    expect(page).to have_content("Theo")
  end
end
