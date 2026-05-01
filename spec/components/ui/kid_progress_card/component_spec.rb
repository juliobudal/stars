require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::KidProgressCard::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:kid) { create(:profile, :child, name: "Lila", points: 42) }

  it "renders kid name, balance, and missions count" do
    render_inline(described_class.new(kid: kid, awaiting_count: 0, missions_count: 3))
    expect(page).to have_text("Lila")
    expect(page).to have_text("42")
    expect(page).to have_text("3")
  end

  it "shows awaiting badge when count > 0" do
    render_inline(described_class.new(kid: kid, awaiting_count: 2, missions_count: 0))
    expect(page).to have_text("2 pendentes")
  end

  it "hides awaiting badge at 0" do
    render_inline(described_class.new(kid: kid, awaiting_count: 0, missions_count: 0))
    expect(page).not_to have_text("aguardando aprovação")
  end

  it "wraps root in data-palette matching kid color" do
    kid = build_stubbed(:profile, color: "rose", role: :child, name: "Zoe", points: 12)
    render_inline(described_class.new(kid: kid, awaiting_count: 0, missions_count: 0))

    expect(page).to have_css('[data-palette="rose"]', count: 1)
  end

  it "uses 'primary' palette when kid color is blank" do
    kid = build_stubbed(:profile, color: nil, role: :child, name: "Anon", points: 0)
    render_inline(described_class.new(kid: kid, awaiting_count: 0, missions_count: 0))

    expect(page).to have_css('[data-palette="primary"]', count: 1)
  end

  describe "Meta atual line" do
    let(:family) { create(:family) }
    let(:kid)    { create(:profile, :child, family: family, name: "Lila", points: 42) }

    it "renders 'Sem meta' when no wishlist is set" do
      render_inline(described_class.new(kid: kid, awaiting_count: 0, missions_count: 0))
      expect(page).to have_text("Sem meta")
    end

    it "renders 'Meta:' and the reward title when wishlist is set" do
      reward = create(:reward, family: family, title: "LEGO Star Wars", cost: 200)
      kid.update!(wishlist_reward: reward)

      render_inline(described_class.new(kid: kid, awaiting_count: 0, missions_count: 0))
      expect(page).to have_text("Meta:")
      expect(page).to have_text("LEGO Star Wars")
    end

    it "does not render any link or form to mutate the wishlist (read-only)" do
      reward = create(:reward, family: family, title: "Switch", cost: 500)
      kid.update!(wishlist_reward: reward)

      render_inline(described_class.new(kid: kid, awaiting_count: 0, missions_count: 0))
      expect(page).not_to have_css("a[href*='wishlist']")
      expect(page).not_to have_css("form[action*='wishlist']")
    end
  end
end
