require "rails_helper"

RSpec.describe "Parent dashboard kid card palette", type: :system, js: true do
  it "renders each kid's card wrapped in their data-palette" do
    family = create(:family, name: "Fam", email: "parent@example.com",
                             password: "supersecret1234")
    parent = create(:profile, :parent, family: family, name: "Mom",
                                       pin: "1234", email: "mom@example.com")
    create(:profile, :child, family: family, name: "Theo",
                             color: "mint", pin: "1234")
    create(:profile, :child, family: family, name: "Zoe",
                             color: "rose", pin: "1234")

    sign_in_as_parent(parent)

    expect(page).to have_css('[data-palette="mint"]', wait: 5)
    expect(page).to have_css('[data-palette="rose"]', wait: 5)
  end
end
