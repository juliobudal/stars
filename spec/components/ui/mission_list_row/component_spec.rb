require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::MissionListRow::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:family) { create(:family) }
  let(:mission) { create(:global_task, family: family, title: "Arrumar cama", points: 20, category: :casa, frequency: :daily) }
  let(:kid) { create(:profile, :child, family: family, name: "Theo", color: "sky") }

  it "renders title, points and assigned kid initials" do
    render_inline(described_class.new(mission: mission, assigned_profiles: [ kid ]))
    expect(page).to have_text("Arrumar cama")
    expect(page).to have_text("20")
    expect(page).to have_text("T")
  end

  it "tags the row with inactive panel key when inactive" do
    mission.update!(active: false)
    render_inline(described_class.new(mission: mission, assigned_profiles: []))
    expect(page.native.to_html).to include("inactive")
  end
end
