# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Skills::Award do
  let(:learner_id) { 42 }
  let(:skill) { Academy::Skill.find_or_create_by!(slug: "foco") { |s| s.name = "Foco"; s.icon = "target"; s.position = 4 } }
  let(:mission) { create(:academy_mission) }

  before do
    create(:academy_aula_skill, mission: mission, skill: skill, weight: 2)
  end

  def progress_for(mission)
    Academy::MissionProgress.create!(
      learner_id: learner_id, mission: mission, status: :in_progress, started_at: Time.current
    )
  end

  describe ":completed" do
    it "credita pontos ao learner" do
      progress_for(mission)
      described_class.call(learner_id: learner_id, mission: mission, event: :completed)
      score = Academy::LearnerSkill.find_by(learner_id: learner_id, skill_id: skill.id).score
      expect(score).to eq(10) # weight 2 → +5×2
    end

    it "não credita de novo quando skills_awarded_at já foi estampado" do
      progress = progress_for(mission)
      described_class.call(learner_id: learner_id, mission: mission, event: :completed)
      progress.update_columns(skills_awarded_at: Time.current)

      result = described_class.call(learner_id: learner_id, mission: mission, event: :completed)
      expect(result.data).to eq(:already_awarded)
      score = Academy::LearnerSkill.find_by(learner_id: learner_id, skill_id: skill.id).score
      expect(score).to eq(10) # ainda 10
    end

    it "credita normalmente quando o stamp é em outra missão" do
      other = create(:academy_mission)
      create(:academy_aula_skill, mission: other, skill: skill, weight: 2)
      progress_for(mission).update_columns(skills_awarded_at: Time.current)
      progress_for(other)

      described_class.call(learner_id: learner_id, mission: other, event: :completed)
      score = Academy::LearnerSkill.find_by(learner_id: learner_id, skill_id: skill.id).score
      expect(score).to eq(10)
    end
  end

  describe "unknown event" do
    it "fails with explanatory message" do
      progress_for(mission)
      result = described_class.call(learner_id: learner_id, mission: mission, event: :challenge_done)
      expect(result.success?).to be false
      expect(result.error).to match(/Evento desconhecido/)
    end
  end
end
