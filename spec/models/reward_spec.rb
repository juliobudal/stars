# == Schema Information
#
# Table name: rewards
#
#  id          :bigint           not null, primary key
#  cost        :integer
#  icon        :string
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category_id :bigint           not null
#  family_id   :bigint           not null
#
# Indexes
#
#  index_rewards_on_category_id  (category_id)
#  index_rewards_on_family_id    (family_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (family_id => families.id)
#
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
