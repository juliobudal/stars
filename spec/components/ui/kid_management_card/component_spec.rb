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
end
