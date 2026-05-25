# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Subject do
  describe "associations" do
    it "has_many missions and trails (destroy guarded)" do
      reflection_missions = described_class.reflect_on_association(:missions)
      reflection_trails   = described_class.reflect_on_association(:trails)
      expect(reflection_missions.macro).to eq(:has_many)
      expect(reflection_missions.class_name).to eq("Academy::Mission")
      expect(reflection_missions.options[:dependent]).to eq(:restrict_with_error)
      expect(reflection_trails.macro).to eq(:has_many)
      expect(reflection_trails.class_name).to eq("Academy::Trail")
      expect(reflection_trails.options[:dependent]).to eq(:restrict_with_error)
    end
  end

  describe "validations" do
    it "requires slug and name" do
      record = described_class.new
      expect(record).not_to be_valid
      expect(record.errors[:slug]).to be_present
      expect(record.errors[:name]).to be_present
    end

    it "requires slug uniqueness" do
      create(:academy_subject, slug: "uniq-slug-1")
      dup = described_class.new(slug: "uniq-slug-1", name: "X")
      expect(dup).not_to be_valid
      expect(dup.errors[:slug]).to be_present
    end

    it "rejects slugs with invalid characters" do
      record = described_class.new(slug: "Bad Slug!", name: "X")
      expect(record).not_to be_valid
      expect(record.errors[:slug]).to be_present
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      record = described_class.new(slug: "param-slug", name: "X")
      expect(record.to_param).to eq("param-slug")
    end
  end

  describe ".active" do
    it "orders by position then id and excludes inactive rows" do
      on  = create(:academy_subject, active: true,  position: 9001)
      off = create(:academy_subject, active: false, position: 9002)
      on2 = create(:academy_subject, active: true,  position: 9000)

      ordered_targets = described_class.active.where(id: [ on.id, off.id, on2.id ])
      expect(ordered_targets).to eq([ on2, on ])
    end
  end

  describe ".skills_for" do
    let(:s) { create(:academy_subject) }
    let(:concept) { create(:academy_concept) }
    let!(:m1) { create(:academy_mission, subject: s, concept: concept, active: true) }
    let!(:m2) { create(:academy_mission, subject: s, concept: concept, active: true) }

    it "returns a Skill struct with computed level/total/ratio/tier" do
      Academy::MissionProgress.create!(learner_id: 99, mission: m1, status: :completed)
      result = described_class.skills_for(99, subjects: [ s ])
      skill = result.fetch(s.id)

      expect(skill.total).to eq(2)
      expect(skill.level).to eq(1)
      expect(skill.tier).to eq(:apprentice)
    end

    it "returns a novato skill when there are no missions" do
      empty_subject = create(:academy_subject)
      result = described_class.skills_for(1, subjects: [ empty_subject ])
      expect(result.fetch(empty_subject.id).tier).to eq(:novato)
    end
  end
end
