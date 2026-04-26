require 'rails_helper'

RSpec.describe Streaks::CheckService do
  let(:family) { create(:family) }
  let(:profile) { create(:profile, :child, family: family, points: 100) }

  describe '.call' do
    context 'when no threshold or streak hit' do
      it 'returns nil' do
        result = described_class.call(profile, points_before: 100, points_after: 110)
        expect(result).to be_nil
      end
    end

    context 'when crossing a threshold (50)' do
      it 'returns :threshold tier with the threshold value' do
        result = described_class.call(profile, points_before: 49, points_after: 55)
        expect(result).to be_a(Hash)
        expect(result[:tier]).to eq(:threshold)
        expect(result[:payload][:threshold]).to eq(50)
      end
    end

    context 'when crossing 100' do
      it 'returns :threshold with 100' do
        result = described_class.call(profile, points_before: 99, points_after: 105)
        expect(result[:payload][:threshold]).to eq(100)
      end
    end

    context 'when crossing two thresholds at once (49 -> 105)' do
      it 'returns the highest crossed threshold' do
        result = described_class.call(profile, points_before: 49, points_after: 105)
        expect(result[:payload][:threshold]).to eq(100)
      end
    end

    context 'when streak day is hit (3 consecutive days of earn logs)' do
      before do
        2.downto(0) do |days_ago|
          create(:activity_log, profile: profile, log_type: :earn, points: 5, created_at: days_ago.days.ago)
        end
      end

      it 'returns :streak tier with day count' do
        result = described_class.call(profile, points_before: 95, points_after: 100)
        expect(result[:tier]).to eq(:streak)
        expect(result[:payload][:days]).to eq(3)
      end
    end

    context 'when streak gap breaks the chain' do
      before do
        create(:activity_log, profile: profile, log_type: :earn, points: 5, created_at: 0.days.ago)
        create(:activity_log, profile: profile, log_type: :earn, points: 5, created_at: 1.day.ago)
        create(:activity_log, profile: profile, log_type: :earn, points: 5, created_at: 3.days.ago)
      end

      it 'does NOT return :streak (chain broken)' do
        result = described_class.call(profile, points_before: 5, points_after: 10)
        expect(result).to be_nil
      end
    end

    context 'when service raises internally' do
      it 'returns nil and logs warning' do
        allow(profile).to receive(:activity_logs).and_raise(StandardError, "boom")
        expect(Rails.logger).to receive(:warn).with(/Streaks::CheckService/)
        result = described_class.call(profile, points_before: 0, points_after: 5)
        expect(result).to be_nil
      end
    end
  end
end
