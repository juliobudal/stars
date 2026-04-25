require "rails_helper"

RSpec.describe "Profile pick + PIN flow", type: :system, js: true do
  let!(:family) { Family.create!(name: "Fam", email: "fam@example.com", password: "supersecret1234") }
  let!(:kid)    { family.profiles.create!(name: "Lila", role: :child, pin: "1234") }

  it "lets a kid log in with PIN" do
    sign_in_family(family)

    click_on "Lila"
    expect(page).to have_css("button.pin-key", wait: 5)
    fill_pin("1234")

    expect(page).to have_current_path(kid_root_path, ignore_query: true)
  end
end
