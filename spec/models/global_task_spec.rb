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
    it { is_expected.to define_enum_for(:frequency).with_values(daily: 0, weekly: 1, monthly: 2, once: 3) }
  end

  describe "monthly validations" do
    context "when frequency is monthly" do
      subject(:task) { build(:global_task, frequency: :monthly) }

      it "requires day_of_month" do
        task.day_of_month = nil
        expect(task).not_to be_valid
        expect(task.errors[:day_of_month]).not_to be_empty
      end

      it "accepts day_of_month in 1..31" do
        task.day_of_month = 15
        expect(task).to be_valid
      end

      it "rejects day_of_month = 0" do
        task.day_of_month = 0
        expect(task).not_to be_valid
      end

      it "rejects day_of_month = 32" do
        task.day_of_month = 32
        expect(task).not_to be_valid
      end
    end

    context "when frequency is not monthly" do
      it "does not require day_of_month" do
        task = build(:global_task, frequency: :daily, day_of_month: nil)
        expect(task).to be_valid
      end
    end
  end
end
