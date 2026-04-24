# == Schema Information
#
# Table name: rewards
#
#  id         :bigint           not null, primary key
#  category   :integer          default("outro"), not null
#  cost       :integer
#  icon       :string
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  family_id  :bigint           not null
#
# Indexes
#
#  index_rewards_on_family_id  (family_id)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#
require "rails_helper"

RSpec.describe Reward, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:family) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_numericality_of(:cost).is_greater_than(0) }
  end
end
