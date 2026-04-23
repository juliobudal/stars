require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::ApprovalRow::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:kid) { create(:profile, :child, name: "Theo") }

  it "renders title, points and two buttons" do
    render_inline(described_class.new(
      kid: kid,
      title: "Escovar dentes",
      meta: "há 2h",
      points: 10,
      approve_url: "/approve",
      reject_url: "/reject"
    ))
    expect(page).to have_text("Escovar dentes")
    expect(page).to have_text("+10 ★")
    expect(page).to have_css("form[action='/approve']")
    expect(page).to have_css("form[action='/reject']")
  end

  it "uses minus sign for redemption rows" do
    render_inline(described_class.new(
      kid: kid, title: "Sorvete", meta: "agora", points: 30,
      points_sign: "−",
      approve_url: "/a", reject_url: "/r"
    ))
    expect(page).to have_text("−30 ★")
  end
end
