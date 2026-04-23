require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::ActivityRow::Component, type: :component do
  include ViewComponent::TestHelpers

  it "renders with explicit args" do
    render_inline(described_class.new(
      kid: nil,
      description: "Bonus",
      timestamp: nil,
      amount: 5,
      direction: "earn",
      with_divider: false
    ))
    expect(page).to have_text("Bonus")
    expect(page).to have_text("+5 ⭐")
  end

  it "renders spend with minus sign" do
    render_inline(described_class.new(
      kid: nil, description: "Prêmio", timestamp: nil,
      amount: -10, direction: "spend", with_divider: false
    ))
    expect(page).to have_text("−10 ⭐")
  end
end
