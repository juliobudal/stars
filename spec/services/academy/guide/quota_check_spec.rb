# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Guide::QuotaCheck do
  let(:mission) { create(:academy_mission) }
  let(:learner) { Academy::Learner.new(id: 555, display_name: "Theo", age_band: "kid", timezone: "America/Sao_Paulo") }

  it "returns new_session_available when no conversation exists today" do
    result = described_class.call(learner: learner, mission: mission)
    expect(result.data[:session_state]).to eq(:new_session_available)
    expect(result.data[:can_send]).to be(true)
    expect(result.data[:remaining_messages]).to eq(5)
  end

  context "with an open conversation" do
    let!(:convo) { create(:academy_guide_conversation, learner_id: learner.id, mission: mission, started_at: Time.current) }

    it "decrements remaining as user messages are added" do
      2.times { create(:academy_guide_message, conversation: convo, role: :user) }
      result = described_class.call(learner: learner, mission: mission)
      expect(result.data[:session_state]).to eq(:open)
      expect(result.data[:remaining_messages]).to eq(3)
      expect(result.data[:can_send]).to be(true)
    end

    it "blocks send when 5 user messages already exist" do
      5.times { create(:academy_guide_message, conversation: convo, role: :user) }
      result = described_class.call(learner: learner, mission: mission)
      expect(result.data[:remaining_messages]).to eq(0)
      expect(result.data[:can_send]).to be(false)
    end
  end

  it "returns closed_today when today's conversation is closed" do
    create(:academy_guide_conversation, learner_id: learner.id, mission: mission, started_at: 2.hours.ago, closed_at: 1.hour.ago)
    result = described_class.call(learner: learner, mission: mission)
    expect(result.data[:session_state]).to eq(:closed_today)
    expect(result.data[:can_send]).to be(false)
  end

  it "treats a conversation from a previous local-TZ day as new_session_available" do
    travel_to Time.zone.local(2026, 5, 19, 9, 0, 0) do
      create(:academy_guide_conversation, learner_id: learner.id, mission: mission, started_at: 36.hours.ago)
      result = described_class.call(learner: learner, mission: mission)
      expect(result.data[:session_state]).to eq(:new_session_available)
    end
  end
end
