require 'rails_helper'

RSpec.describe Rewards::WeeklyFamilyGoalService do
  include ActiveSupport::Testing::TimeHelpers

  let(:family) { create(:family) }
  let(:kid1) { create(:profile, :child, family: family) }
  let(:kid2) { create(:profile, :child, family: family) }

  describe '#call' do
    context 'with no collective rewards' do
      it 'returns empty target' do
        result = described_class.call(family: family)
        expect(result.success?).to be true
        expect(result.data[:target]).to be_nil
        expect(result.data[:eligible]).to be false
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
        expect(result.data[:target]).to eq(small)
        expect(result.data[:eligible]).to be true
      end

      it 'targets next unreached reward when below smallest goal' do
        create(:activity_log, profile: kid1, log_type: :earn, points: 30)

        result = described_class.call(family: family)
        expect(result.data[:target]).to eq(small)
        expect(result.data[:eligible]).to be false
        expect(result.data[:progress_pct]).to eq(30)
      end

      it 'picks largest reached when multiple eligible' do
        create(:activity_log, profile: kid1, log_type: :earn, points: 600)

        result = described_class.call(family: family)
        expect(result.data[:target]).to eq(big)
        expect(result.data[:eligible]).to be true
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
    end
  end
end
