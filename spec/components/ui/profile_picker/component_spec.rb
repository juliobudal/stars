require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::ProfilePicker::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:family) { create(:family) }
  let!(:parent_profile) { create(:profile, :parent, family: family, name: "Mãe") }
  let!(:child_profile)  { create(:profile, :child,  family: family, name: "Joaquim", points: 42) }

  it "renders one card per profile with names and points" do
    render_inline(described_class.new(profiles: family.profiles))
    expect(page).to have_text("Mãe")
    expect(page).to have_text("Joaquim")
    expect(page).to have_text("42")
  end

  it "tags parent profiles as RESPONSÁVEL with a lock badge" do
    render_inline(described_class.new(profiles: family.profiles))
    expect(page).to have_text("Responsável")
  end

  it "marks the selected profile as visually selected" do
    render_inline(described_class.new(profiles: family.profiles, selected: child_profile))
    selected_link = page.find("a", text: "Joaquim")
    expect(selected_link[:style]).to include("var(--primary)")
  end

  it "exposes the selected profile id via data attribute for the controller" do
    render_inline(described_class.new(profiles: family.profiles, selected: parent_profile))
    expect(page.find("[data-controller='profile-picker']")[:"data-profile-picker-selected-id-value"]).to eq(parent_profile.id.to_s)
  end

  it "renders the pin_modal turbo frame and a PinModal when a profile is selected" do
    render_inline(described_class.new(profiles: family.profiles, selected: parent_profile))
    expect(page).to have_css("turbo-frame#pin_modal")
    expect(page).to have_text("Olá, Mãe!")
  end

  it "leaves the pin_modal turbo frame empty when nothing is selected" do
    render_inline(described_class.new(profiles: family.profiles))
    frame = page.find("turbo-frame#pin_modal")
    expect(frame).to have_no_text("Olá")
  end
end
