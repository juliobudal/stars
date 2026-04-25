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
    expect(page).to have_text("+5")
    expect(page).to have_css("i.hgi-star")
  end

  it "renders spend with minus sign" do
    render_inline(described_class.new(
      kid: nil, description: "Prêmio", timestamp: nil,
      amount: -10, direction: "spend", with_divider: false
    ))
    expect(page).to have_text("−10")
    expect(page).to have_css("i.hgi-star")
  end

  context "data-palette wrapper" do
    let(:kid) { build_stubbed(:profile, color: "peach", role: :child, name: "Zoe", points: 0) }

    it "wraps root in data-palette matching kid color" do
      render_inline(described_class.new(
        kid: kid,
        description: "Earned a star",
        timestamp: Time.current,
        amount: 5,
        direction: "earn"
      ))

      expect(page).to have_css('[data-palette="peach"]', count: 1)
    end

    it "uses 'primary' palette when kid color is blank" do
      blank_kid = build_stubbed(:profile, color: nil, role: :child, name: "Anon", points: 0)
      render_inline(described_class.new(
        kid: blank_kid,
        description: "Earned a star",
        timestamp: Time.current,
        amount: 5,
        direction: "earn"
      ))

      expect(page).to have_css('[data-palette="primary"]', count: 1)
    end
  end
end
