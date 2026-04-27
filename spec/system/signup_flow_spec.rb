require "rails_helper"

RSpec.describe "Family signup flow", type: :system do
  it "creates a family then first parent profile and lands on parent dashboard" do
    visit new_registration_path

    fill_in "Nome da família", with: "Os Silva"
    fill_in "Email", with: "silva@example.com"
    fill_in "Senha (mín. 12 caracteres)", with: "supersecret1234"
    click_on "Criar"

    expect(page).to have_current_path(new_parent_profile_path(onboarding: true))

    fill_in "Seu nome", with: "Mamãe Silva"
    fill_in "PIN (4 dígitos)", with: "5555"
    click_on "Salvar perfil"

    expect(page).to have_current_path(parent_root_path)
    expect(Family.find_by(email: "silva@example.com")).to be_present
  end
end
