require "rails_helper"

RSpec.describe "Parent invite flow", type: :system do
  let!(:family) { Family.create!(name: "Fam", email: "fam@example.com", password: "supersecret1234") }
  let!(:invitation) do
    family.profile_invitations.create!(
      email: "newparent@example.com", token: SecureRandom.hex(16),
      expires_at: 1.day.from_now
    )
  end

  it "invitee accepts → onboarding → new parent profile" do
    visit invitation_acceptance_path(token: invitation.token)
    click_on "Aceitar convite"

    expect(page).to have_current_path(new_parent_profile_path(onboarding: true, invited: true))

    fill_in "Seu nome", with: "Tia Ana"
    fill_in "PIN (4 dígitos)", with: "7777"
    click_on "Salvar perfil"

    expect(page).to have_current_path(parent_root_path)
    expect(family.reload.profiles.where(role: :parent).pluck(:name)).to include("Tia Ana")
  end
end
