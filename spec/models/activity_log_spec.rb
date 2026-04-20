require "rails_helper"

RSpec.describe ActivityLog, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:profile) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:log_type).with_values(earn: 0, redeem: 1, adjust: 2) }
  end

  describe "scopes" do
    describe ".recent" do
      it "returns the 10 most recent logs" do
        profile = create(:profile)
        12.times { create(:activity_log, profile: profile) }
        expect(ActivityLog.recent.count).to eq(10)
      end
    end
  end
end
