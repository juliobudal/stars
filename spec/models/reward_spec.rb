require "rails_helper"

RSpec.describe Reward, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:family) }
    it { is_expected.to belong_to(:category) }
  end

  describe "validations" do
    subject { build(:reward) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_numericality_of(:cost).is_greater_than(0) }
  end

  describe "category restriction on delete" do
    it "blocks category delete when reward is attached" do
      family = create(:family)
      category = family.categories.first
      create(:reward, family: family, category: category)
      expect { category.destroy }.not_to change { Category.count }
      expect(category.errors[:base].join).to match(/dependentes|dependent/i)
    end
  end
end
