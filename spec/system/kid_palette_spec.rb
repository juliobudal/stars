require "rails_helper"

RSpec.describe "Kid layout palette", type: :system, js: true do
  it "renders body with data-palette matching the signed-in kid's color" do
    family = create(:family, email: "mint@example.com")
    kid = create(:profile, :child, family: family, name: "Theo", color: "mint", pin: "1234")

    sign_in_as_child(kid)

    expect(page).to have_css('body[data-palette="mint"]', wait: 5)
  end

  it "falls back to 'primary' when the kid has no color set" do
    family = create(:family, email: "anon@example.com")
    kid = create(:profile, :child, family: family, name: "Anon", color: nil, pin: "1234")

    sign_in_as_child(kid)

    expect(page).to have_css('body[data-palette="primary"]', wait: 5)
  end
end
