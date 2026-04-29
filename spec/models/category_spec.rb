# == Schema Information
#
# Table name: categories
#
#  id         :bigint           not null, primary key
#  color      :string           not null
#  icon       :string           not null
#  name       :string           not null
#  position   :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  family_id  :bigint           not null
#
# Indexes
#
#  index_categories_on_family_id               (family_id)
#  index_categories_on_family_id_and_name      (family_id,name) UNIQUE
#  index_categories_on_family_id_and_position  (family_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#
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
