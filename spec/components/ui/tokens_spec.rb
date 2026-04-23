require "rails_helper"

RSpec.describe Ui::Tokens do
  it "returns category metadata for known key" do
    expect(described_class.category_for("casa")).to include(label: "Casa", icon: "home", tint: "mint")
  end

  it "falls back to 'geral' for unknown category" do
    expect(described_class.category_for("banana")).to eq(described_class::MISSION_CATEGORIES["geral"])
  end

  it "returns frequency metadata for known key" do
    expect(described_class.frequency_for("weekly")).to include(label: "Semanal")
  end

  it "resolves tint soft for primary vs named" do
    expect(described_class.tint_soft("primary")).to eq("var(--primary-soft)")
    expect(described_class.tint_soft("mint")).to eq("var(--c-mint-soft)")
  end

  it "resolves tint foreground" do
    expect(described_class.tint_fg("primary")).to eq("var(--primary)")
    expect(described_class.tint_fg("mint")).to eq("var(--c-mint)")
  end
end
