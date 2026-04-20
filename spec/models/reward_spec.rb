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
