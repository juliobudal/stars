require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::ProgressSteps::Component, type: :component do
  include ViewComponent::TestHelpers

  it "renders one segment per step" do
    render_inline(described_class.new(current: 1, total: 4))
    expect(page).to have_css("[role='progressbar'] > div", count: 4)
  end

  it "fills only the first `current` segments with the primary color" do
    render_inline(described_class.new(current: 2, total: 4))
    segments = page.find_all("[role='progressbar'] > div")
    expect(segments[0]["style"]).to include("var(--primary)")
    expect(segments[1]["style"]).to include("var(--primary)")
    expect(segments[2]["style"]).to include("var(--surface-2)")
    expect(segments[3]["style"]).to include("var(--surface-2)")
  end

  it "exposes aria progressbar metadata" do
    render_inline(described_class.new(current: 3, total: 4))
    bar = page.find("[role='progressbar']")
    expect(bar["aria-valuenow"]).to eq("3")
    expect(bar["aria-valuemin"]).to eq("0")
    expect(bar["aria-valuemax"]).to eq("4")
  end

  it "clamps current within [0, total]" do
    render_inline(described_class.new(current: 99, total: 4))
    segments = page.find_all("[role='progressbar'] > div")
    expect(segments.count { |s| s["style"].include?("var(--primary)") }).to eq(4)
  end
end
