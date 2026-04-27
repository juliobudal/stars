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
end
