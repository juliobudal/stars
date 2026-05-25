# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::PracticeWager do
  let(:mission) { create(:academy_mission) }

  describe "associations" do
    it "belongs_to :mission" do
      reflection = described_class.reflect_on_association(:mission)
      expect(reflection.macro).to eq(:belongs_to)
      expect(reflection.class_name).to eq("Academy::Mission")
    end
  end

  describe "validations" do
    it "requires learner_id and guide_bet_count" do
      record = described_class.new(mission: mission)
      expect(record).not_to be_valid
      expect(record.errors[:learner_id]).to be_present
      expect(record.errors[:guide_bet_count]).to be_present
    end

    it "requires guide_bet_count > 0 integer" do
      record = described_class.new(mission: mission, learner_id: 1, guide_bet_count: 0)
      expect(record).not_to be_valid
      expect(record.errors[:guide_bet_count]).to be_present
    end

    it "is unique per (learner_id, mission_id)" do
      described_class.create!(learner_id: 1, mission: mission, guide_bet_count: 5)
      dup = described_class.new(learner_id: 1, mission: mission, guide_bet_count: 1)
      expect(dup).not_to be_valid
    end

    it "rejects parent_observation outside the allowed list" do
      record = described_class.new(learner_id: 1, mission: mission, guide_bet_count: 1, parent_observation: "bogus")
      expect(record).not_to be_valid
    end

    it "accepts each documented parent_observation value" do
      described_class::PARENT_OBSERVATIONS.each_with_index do |obs, i|
        record = described_class.new(learner_id: 10 + i, mission: mission, guide_bet_count: 1, parent_observation: obs)
        expect(record).to be_valid, "expected #{obs.inspect} to be valid (errors: #{record.errors.full_messages})"
      end
    end
  end

  describe "scopes" do
    let!(:pending)  { described_class.create!(learner_id: 1, mission: mission, guide_bet_count: 1, reported_at: nil) }
    let!(:reported) { described_class.create!(learner_id: 2, mission: mission, guide_bet_count: 2, reported_at: Time.current) }

    it ".pending returns wagers without reported_at" do
      expect(described_class.pending).to include(pending)
      expect(described_class.pending).not_to include(reported)
    end

    it ".reported returns wagers with reported_at" do
      expect(described_class.reported).to include(reported)
      expect(described_class.reported).not_to include(pending)
    end

    it ".for_learner scopes by learner_id" do
      expect(described_class.for_learner(1)).to contain_exactly(pending)
    end
  end
end
