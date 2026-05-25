# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::MissionProgress do
  let(:mission) { create(:academy_mission) }

  describe "associations" do
    it "belongs_to :mission" do
      reflection = described_class.reflect_on_association(:mission)
      expect(reflection.macro).to eq(:belongs_to)
      expect(reflection.class_name).to eq("Academy::Mission")
    end

    it "has_many :sessions (destroy)" do
      reflection = described_class.reflect_on_association(:sessions)
      expect(reflection.macro).to eq(:has_many)
      expect(reflection.class_name).to eq("Academy::Session")
      expect(reflection.options[:dependent]).to eq(:destroy)
    end
  end

  describe "validations" do
    it "requires learner_id" do
      record = described_class.new(mission: mission)
      expect(record).not_to be_valid
      expect(record.errors[:learner_id]).to be_present
    end

    it "is unique per (learner_id, mission_id)" do
      create(:academy_mission_progress, learner_id: 1, mission: mission)
      dup = described_class.new(learner_id: 1, mission: mission)
      expect(dup).not_to be_valid
      expect(dup.errors[:learner_id]).to be_present
    end
  end

  describe "enum :status" do
    it "defines status with the documented integer values" do
      expect(described_class.statuses).to eq(
        "not_started" => 0, "in_progress" => 1, "completed" => 2, "mastered" => 3
      )
    end
  end

  describe "#accuracy" do
    it "returns 0.0 when there are no checkpoints" do
      progress = build(:academy_mission_progress, total_checkpoints: 0, correct_checkpoints: 0)
      expect(progress.accuracy).to eq(0.0)
    end

    it "computes the ratio of correct to total checkpoints" do
      progress = build(:academy_mission_progress, total_checkpoints: 4, correct_checkpoints: 3)
      expect(progress.accuracy).to eq(0.75)
    end
  end
end
