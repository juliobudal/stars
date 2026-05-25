# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::LearnerSignal do
  let(:subject_) { create(:academy_subject) }

  describe "associations" do
    it "belongs_to :subject" do
      reflection = described_class.reflect_on_association(:subject)
      expect(reflection.macro).to eq(:belongs_to)
      expect(reflection.class_name).to eq("Academy::Subject")
    end
  end

  describe "validations" do
    it "requires learner_id" do
      record = described_class.new(subject: subject_)
      expect(record).not_to be_valid
      expect(record.errors[:learner_id]).to be_present
    end

    it "is unique per (learner_id, subject_id)" do
      described_class.create!(subject: subject_, learner_id: 1)
      dup = described_class.new(subject: subject_, learner_id: 1)
      expect(dup).not_to be_valid
    end
  end

  describe ".for_learner" do
    let(:other_subject) { create(:academy_subject) }
    let!(:s1)    { described_class.create!(subject: subject_,      learner_id: 1) }
    let!(:s2)    { described_class.create!(subject: other_subject, learner_id: 1) }
    let!(:other) { described_class.create!(subject: subject_,      learner_id: 2) }

    it "scopes by learner_id" do
      expect(described_class.for_learner(1)).to contain_exactly(s1, s2)
    end
  end
end
