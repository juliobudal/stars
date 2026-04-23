require "rails_helper"

RSpec.describe GlobalTask, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:family) }
    it { is_expected.to have_many(:profile_tasks).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_numericality_of(:points).is_greater_than(0) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:category).with_values(escola: 0, casa: 1, rotina: 2, saude: 3, outro: 4) }
    it { is_expected.to define_enum_for(:frequency).with_values(daily: 0, weekly: 1) }
  end
end
