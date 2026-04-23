require "rails_helper"

RSpec.describe StarDecayJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  describe "#perform" do
    let(:family) { create(:family, decay_enabled: true, allow_negative: false) }
    let(:profile) { create(:profile, :child, family: family, points: 50) }

    def old_earn_log(profile:, points: 10, title: "Old Task")
      travel_to 31.days.ago do
        create(:activity_log, profile: profile, log_type: :earn, points: points, title: title)
      end
    end

    def recent_earn_log(profile:, points: 10)
      create(:activity_log, profile: profile, log_type: :earn, points: points, title: "Recent Task")
    end

    it "creates a decay log and decrements points for an old earn log" do
      log = old_earn_log(profile: profile, points: 10)

      described_class.new.perform

      expect(log.reload.decayed_at).not_to be_nil
      expect(profile.reload.points).to eq(40)
      decay = ActivityLog.decay.last
      expect(decay.profile).to eq(profile)
      expect(decay.points).to eq(-10)
      expect(decay.title).to eq("Expirou: #{log.title}")
    end

    it "is idempotent — running twice creates only one decay log and decrements points once" do
      old_earn_log(profile: profile, points: 10)

      described_class.new.perform
      described_class.new.perform

      expect(ActivityLog.decay.count).to eq(1)
      expect(profile.reload.points).to eq(40)
    end

    it "does not decay logs for families with decay_enabled: false" do
      family.update!(decay_enabled: false)
      old_earn_log(profile: profile)

      described_class.new.perform

      expect(ActivityLog.decay.count).to eq(0)
      expect(profile.reload.points).to eq(50)
    end

    it "does not decay earn logs within the 30-day window" do
      recent_earn_log(profile: profile, points: 10)

      described_class.new.perform

      expect(ActivityLog.decay.count).to eq(0)
      expect(profile.reload.points).to eq(50)
    end

    context "when allow_negative is false" do
      it "floors points at 0 instead of going negative" do
        profile.update!(points: 5)
        old_earn_log(profile: profile, points: 10)

        described_class.new.perform

        expect(profile.reload.points).to eq(0)
      end
    end

    context "when allow_negative is true" do
      it "allows points to go below 0" do
        family.update!(allow_negative: true)
        profile.update!(points: 5)
        old_earn_log(profile: profile, points: 10)

        described_class.new.perform

        expect(profile.reload.points).to eq(-5)
      end
    end
  end
end
