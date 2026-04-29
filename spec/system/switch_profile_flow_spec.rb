require "rails_helper"

RSpec.describe "Switch profile flow", type: :system, js: true do
  let!(:family) { Family.create!(name: "Fam", email: "fam@example.com", password: "supersecret1234") }
  let!(:kid)    { family.profiles.create!(name: "Lila", role: :child, pin: "1234") }
  let!(:other)  { family.profiles.create!(name: "Theo", role: :child, pin: "5678") }

  # TODO(Task 3): re-enable once Sair moves to Ui::KidTopBar overflow.
  # Plan: docs/superpowers/plans/2026-04-29-ui-audit-p0-a11y-touch.md
  xit "returns to picker, family cookie intact" do
    sign_in_profile(kid, pin: "1234")
    expect(page).to have_current_path(kid_root_path, ignore_query: true)

    click_button "Sair"

    expect(page).to have_current_path(new_profile_session_path)
    expect(page).to have_content("Theo")
  end
end
