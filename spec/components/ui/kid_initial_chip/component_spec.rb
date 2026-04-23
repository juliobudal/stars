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
end
