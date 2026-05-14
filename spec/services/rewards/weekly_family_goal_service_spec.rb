require 'rails_helper'

RSpec.describe Rewards::WeeklyFamilyGoalService do
  include ActiveSupport::Testing::TimeHelpers

  let(:family) { create(:family) }
  let(:kid1) { create(:profile, :child, family: family) }
  let(:kid2) { create(:profile, :child, family: family) }

  describe '#call' do
    context 'with no collective rewards' do
      it 'returns empty goals list' do
        result = described_class.call(family: family)
        expect(result.success?).to be true
        expect(result.data[:goals]).to eq([])
        expect(result.data[:earned]).to eq(0)
      end
    end

    context 'with collective rewards' do
      let!(:small) { create(:reward, family: family, cost: 100, collective: true, title: "Pizza") }
      let!(:big)   { create(:reward, family: family, cost: 500, collective: true, title: "Cinema") }

      it 'sums earns from all family kids this week' do
        create(:activity_log, profile: kid1, log_type: :earn, points: 60)
        create(:activity_log, profile: kid2, log_type: :earn, points: 50)

        result = described_class.call(family: family)
        expect(result.data[:earned]).to eq(110)
      end

      it 'returns one goal entry per collective reward, ordered by cost' do
        result = described_class.call(family: family)
        expect(result.data[:goals].map { |g| g[:reward] }).to eq([ small, big ])
      end

      it 'marks each goal eligible based on earned vs its cost' do
        create(:activity_log, profile: kid1, log_type: :earn, points: 150)

        result = described_class.call(family: family)
        small_goal = result.data[:goals].find { |g| g[:reward] == small }
        big_goal   = result.data[:goals].find { |g| g[:reward] == big }
        expect(small_goal[:eligible]).to be true
        expect(big_goal[:eligible]).to be false
      end

      it 'computes progress_pct per goal, capped at 100' do
        create(:activity_log, profile: kid1, log_type: :earn, points: 600)

        result = described_class.call(family: family)
        expect(result.data[:goals].find { |g| g[:reward] == small }[:progress_pct]).to eq(100)
        expect(result.data[:goals].find { |g| g[:reward] == big }[:progress_pct]).to eq(100)
      end

      it 'excludes earns from previous week' do
        travel_to Time.current.beginning_of_week - 1.day do
          create(:activity_log, profile: kid1, log_type: :earn, points: 200)
        end

        result = described_class.call(family: family)
        expect(result.data[:earned]).to eq(0)
      end

      it 'excludes redeem log_type' do
        create(:activity_log, profile: kid1, log_type: :redeem, points: -50)
        result = described_class.call(family: family)
        expect(result.data[:earned]).to eq(0)
      end

      it 'reflects newly uncollectivized rewards by excluding them from goals' do
        small.update!(collective: false)
        result = described_class.call(family: family)
        expect(result.data[:goals].map { |g| g[:reward] }).to eq([ big ])
      end
    end
  end
end
