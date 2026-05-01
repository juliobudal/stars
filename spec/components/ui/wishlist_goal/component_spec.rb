require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::WishlistGoal::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:family) { create(:family) }

  describe "empty state" do
    let(:child) { create(:profile, :child, family: family, points: 30) }

    it "renders the empty CTA copy" do
      render_inline(described_class.new(profile: child))
      expect(page).to have_text("Escolha um prêmio como meta")
    end

    it "wraps in a turbo frame keyed on dom_id(profile, :wishlist)" do
      render_inline(described_class.new(profile: child))
      # Rails dom_id(model, prefix) emits "<prefix>_<singular_name>_<id>" — i.e.
      # "wishlist_profile_<id>", NOT "profile_<id>_wishlist". Both the component
      # template and Profile#broadcast_wishlist_card use dom_id(profile, :wishlist),
      # so the broadcast target matches the rendered frame id.
      expect(page).to have_css("turbo-frame#wishlist_profile_#{child.id}")
    end

    it "links the empty CTA to kid_rewards_path" do
      render_inline(described_class.new(profile: child))
      expect(page).to have_link(href: "/kid/rewards")
    end
  end

  describe "filled state below funded threshold" do
    let(:child)  { create(:profile, :child, family: family, points: 50) }
    let(:reward) { create(:reward, family: family, title: "LEGO", cost: 100) }

    before { child.update!(wishlist_reward: reward) }

    it "shows the title, reward, ratio, and remaining delta" do
      render_inline(described_class.new(profile: child))
      expect(page).to have_text("Minha meta")
      expect(page).to have_text("LEGO")
      expect(page).to have_text("50/100")
      expect(page).to have_text("Faltam")
      expect(page).to have_text("50") # remaining
    end

    it "does NOT show the redeem CTA" do
      render_inline(described_class.new(profile: child))
      expect(page).not_to have_text("Resgatar agora")
    end
  end

  describe "filled state at funded threshold" do
    let(:child)  { create(:profile, :child, family: family, points: 100) }
    let(:reward) { create(:reward, family: family, title: "Switch", cost: 100) }

    before { child.update!(wishlist_reward: reward) }

    it "shows the redeem CTA and pronto label" do
      render_inline(described_class.new(profile: child))
      expect(page).to have_text("Resgatar agora")
      expect(page).to have_text(/pronto/i)
    end
  end

  describe "helpers" do
    let(:child)  { create(:profile, :child, family: family, points: 250) }
    let(:reward) { create(:reward, family: family, cost: 100) }

    it "caps progress_pct at 100 when points exceed cost" do
      child.update!(wishlist_reward: reward)
      component = described_class.new(profile: child)
      expect(component.progress_pct).to eq(100)
    end

    it "floors stars_remaining at 0 when funded" do
      child.update!(wishlist_reward: reward)
      component = described_class.new(profile: child)
      expect(component.stars_remaining).to eq(0)
    end

    it "returns 0 progress when not pinned" do
      component = described_class.new(profile: child)
      expect(component.progress_pct).to eq(0)
      expect(component.pinned?).to be false
    end
  end
end
