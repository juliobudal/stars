# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Guide::FindOrStartConversation do
  let(:mission) { create(:academy_mission) }
  let(:learner) { Academy::Learner.new(id: 777, display_name: "Theo", age_band: "kid", timezone: "America/Sao_Paulo") }

  it "creates a fresh conversation when none exists today" do
    expect { described_class.call(learner: learner, mission: mission) }
      .to change(Academy::GuideConversation, :count).by(1)
  end

  it "reuses today's conversation across calls" do
    existing = create(:academy_guide_conversation, learner_id: learner.id, mission: mission, started_at: 1.hour.ago)
    expect { described_class.call(learner: learner, mission: mission) }
      .not_to change(Academy::GuideConversation, :count)
    expect(described_class.call(learner: learner, mission: mission).data).to eq(existing)
  end

  it "creates a new conversation when yesterday's session existed (TZ boundary)" do
    travel_to Time.zone.local(2026, 5, 19, 9, 0, 0) do
      create(:academy_guide_conversation, learner_id: learner.id, mission: mission, started_at: 30.hours.ago)
      expect { described_class.call(learner: learner, mission: mission) }
        .to change(Academy::GuideConversation, :count).by(1)
    end
  end
end
