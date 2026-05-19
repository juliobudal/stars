# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::GuideConversation do
  it "requires learner_id, started_at, prompt_version" do
    expect(described_class.new).not_to be_valid
  end

  it "defaults flagged false and flag_reasons empty" do
    convo = create(:academy_guide_conversation)
    expect(convo.flagged).to be(false)
    expect(convo.flag_reasons).to eq([])
  end

  it "defaults prompt_version to guide-persona@v1" do
    convo = Academy::GuideConversation.new(
      learner_id: 1, mission: build(:academy_mission), started_at: Time.current
    )
    convo.save!
    expect(convo.prompt_version).to eq("guide-persona@v1")
  end

  describe "#open? / #closed?" do
    it "tracks closed_at" do
      convo = create(:academy_guide_conversation)
      expect(convo).to be_open
      convo.update!(closed_at: Time.current)
      expect(convo).to be_closed
    end
  end

  describe ".flagged_first" do
    it "orders flagged true ahead of false then by started_at desc" do
      old_flagged = create(:academy_guide_conversation, flagged: true, started_at: 3.days.ago)
      recent_flagged = create(:academy_guide_conversation, flagged: true, started_at: 1.hour.ago)
      recent_unflagged = create(:academy_guide_conversation, started_at: 30.minutes.ago)
      expect(described_class.flagged_first.to_a).to eq([recent_flagged, old_flagged, recent_unflagged])
    end
  end
end
