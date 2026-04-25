require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::KidManagementCard::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:kid) { create(:profile, :child, name: "Lila", color: "peach", points: 340) }

  it "renders name, balance and mission count" do
    render_inline(described_class.new(kid: kid, balance: 340, missions_count: 3))
    expect(page).to have_text("Lila")
    expect(page).to have_text("340")
    expect(page).to have_text("3")
    expect(page).to have_text("Nível")
  end

  it "wraps root in data-palette matching kid color" do
    kid = build_stubbed(:profile, color: "mint", role: :child, name: "Theo", points: 0)
    render_inline(described_class.new(kid: kid))

    expect(page).to have_css('[data-palette="mint"]', count: 1)
  end

  it "uses 'primary' palette when kid color is blank" do
    kid = build_stubbed(:profile, color: nil, role: :child, name: "Anon", points: 0)
    render_inline(described_class.new(kid: kid))

    expect(page).to have_css('[data-palette="primary"]', count: 1)
  end
end
