require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::ProfileCard::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:family) { create(:family) }

  describe "child profile" do
    let(:profile) { create(:profile, :child, name: "Luna", color: "mint", points: 10, family: family) }

    it "renders the profile name" do
      render_inline(described_class.new(profile: profile, url: "/session"))
      expect(page).to have_text("Luna")
    end

    it "renders CRIANÇA chip label" do
      render_inline(described_class.new(profile: profile, url: "/session"))
      expect(page).to have_text("CRIANÇA")
    end

    it "renders the star points subtitle" do
      render_inline(described_class.new(profile: profile, url: "/session"))
      expect(page).to have_text("10 ★")
    end

    it "renders a submit button (form)" do
      render_inline(described_class.new(profile: profile, url: "/session"))
      expect(page).to have_css("button[type='submit']")
    end
  end

  describe "parent profile" do
    let(:profile) { create(:profile, :parent, name: "Ana", color: "primary", family: family) }

    it "renders the profile name" do
      render_inline(described_class.new(profile: profile, url: "/session"))
      expect(page).to have_text("Ana")
    end

    it "renders RESPONSÁVEL chip label" do
      render_inline(described_class.new(profile: profile, url: "/session"))
      expect(page).to have_text("RESPONSÁVEL")
    end

    it "does not render a points subtitle for parent" do
      render_inline(described_class.new(profile: profile, url: "/session"))
      expect(page).not_to have_text("★")
    end
  end

  it "wraps root in data-palette matching profile color" do
    profile = build_stubbed(:profile, color: "sky", role: :child, name: "Theo", points: 0)
    render_inline(described_class.new(profile: profile, url: "/x"))

    expect(page).to have_css('[data-palette="sky"]', count: 1)
  end

  it "uses 'primary' palette when profile color is blank" do
    profile = build_stubbed(:profile, color: nil, role: :child, name: "Anon", points: 0)
    render_inline(described_class.new(profile: profile, url: "/x"))

    expect(page).to have_css('[data-palette="primary"]', count: 1)
  end
end
