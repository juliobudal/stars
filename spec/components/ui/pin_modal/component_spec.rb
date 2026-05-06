require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::PinModal::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:family) { create(:family) }
  let(:profile) { create(:profile, :child, family: family, name: "Mia") }

  it "renders the kid name and the PIN dot row" do
    render_inline(described_class.new(profile: profile))
    expect(page).to have_text("Olá, Mia!")
    expect(page).to have_css(".pin-dots .pin-dot", count: 4)
  end

  it "renders the PIN keypad with digits 0–9 + backspace" do
    render_inline(described_class.new(profile: profile))
    (0..9).each do |n|
      expect(page).to have_button(n.to_s)
    end
    expect(page).to have_css('button[aria-label="Apagar"]')
  end

  it "shows the error message when one is provided" do
    render_inline(described_class.new(profile: profile, error: "PIN incorreto"))
    expect(page).to have_text("PIN incorreto")
  end

  it "does not show an error block when none is provided" do
    render_inline(described_class.new(profile: profile))
    expect(page).not_to have_css(".text-destructive")
  end

  it "submits to profile_session_path with the profile id" do
    render_inline(described_class.new(profile: profile))
    form = page.find("form")
    expect(form["action"]).to eq("/profile_session")
    expect(form).to have_css('input[name="profile_id"]', visible: false)
  end
end
