require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::KidInitialChip::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:profile) { create(:profile, :child, name: "Theo", color: "sky") }

  it "renders the first initial" do
    render_inline(described_class.new(profile: profile))
    expect(page).to have_text("T")
  end

  it "uses the profile's color palette" do
    render_inline(described_class.new(profile: profile))
    expect(page.native.to_html).to include("title=\"Theo\"")
  end

  it "wraps root in data-palette matching profile color" do
    profile = build_stubbed(:profile, color: "coral", role: :child, name: "Lila", points: 0)
    render_inline(described_class.new(profile: profile))

    expect(page).to have_css('[data-palette="coral"]', count: 1)
  end

  it "uses 'primary' palette when profile color is blank" do
    profile = build_stubbed(:profile, color: nil, role: :child, name: "Anon", points: 0)
    render_inline(described_class.new(profile: profile))

    expect(page).to have_css('[data-palette="primary"]', count: 1)
  end
end
