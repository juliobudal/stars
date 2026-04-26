require "rails_helper"

RSpec.describe Categories::SeedDefaultsService do
  let(:family) { create(:family) }

  it "creates 6 default categories with correct names" do
    family.categories.delete_all
    described_class.call(family)
    names = family.categories.reload.pluck(:name)
    expect(names).to match_array(%w[Telinha Docinhos Passeios Brinquedos Experiências Outro])
  end

  it "assigns icon and color to each default" do
    family.categories.delete_all
    described_class.call(family)
    family.categories.reload.each do |c|
      expect(c.icon).to be_present
      expect(c.color).to be_present
    end
  end

  it "is idempotent — second call creates no extra rows" do
    described_class.call(family)
    expect { described_class.call(family) }.not_to change { family.categories.count }
  end
end
