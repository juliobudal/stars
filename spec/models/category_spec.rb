require "rails_helper"

RSpec.describe Category, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:family) }
    it { is_expected.to have_many(:rewards).dependent(:restrict_with_error) }
  end

  describe "validations" do
    subject { build(:category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:icon) }
    it { is_expected.to validate_presence_of(:color) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:family_id).case_insensitive }
  end

  describe "ordering" do
    it "orders by position then created_at via .ordered scope" do
      family = create(:family)
      family.categories.delete_all
      a = create(:category, family: family, name: "A", position: 2)
      b = create(:category, family: family, name: "B", position: 1)
      expect(family.categories.ordered).to eq([ b, a ])
    end
  end
end
