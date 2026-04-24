require "rails_helper"
require "view_component/test_helpers"
require "ostruct"

RSpec.describe Ui::HistoryRow::Component, type: :component do
  include ViewComponent::TestHelpers

  def build_log(type, points: 5, title: "Missão")
    OpenStruct.new(
      log_type: type,
      points: points,
      title: title,
      created_at: Time.zone.local(2026, 4, 23, 10, 30),
      earn?: type.to_s == "earn"
    )
  end

  it "renders earn row with plus sign and Conquista label" do
    render_inline(described_class.new(log: build_log("earn", points: 7)))
    expect(page).to have_text("Missão")
    expect(page).to have_text(/\+7\b/)
    expect(page).to have_text("Conquista")
  end

  it "renders redeem row with minus sign and Compra label" do
    render_inline(described_class.new(log: build_log("redeem", points: 3)))
    expect(page).to have_text(/−3\b/)
    expect(page).to have_text("Compra")
  end

  it "falls back to adjust mapping for unknown type" do
    render_inline(described_class.new(log: build_log("bogus")))
    expect(page).to have_text("Ajuste")
  end
end
