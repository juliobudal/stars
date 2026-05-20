# frozen_string_literal: true

# == Schema Information
#
# Table name: academy_learner_concepts
#
#  id                                                                        :bigint           not null, primary key
#  evolved_to_2_at                                                           :datetime
#  evolved_to_3_at                                                           :datetime
#  first_seen_at                                                             :datetime
#  last_seen_at                                                              :datetime
#  level(0..3 (silhouette → mastered))                                      :integer          default(0), not null
#  seen_in_subjects_count                                                    :integer          default(0), not null
#  created_at                                                                :datetime         not null
#  updated_at                                                                :datetime         not null
#  concept_id                                                                :bigint           not null
#  learner_id(Learner value-object id (no FK by design — module isolation)) :bigint           not null
#
# Indexes
#
#  idx_academy_learner_concepts_level            (learner_id,level)
#  idx_academy_learner_concepts_unique           (learner_id,concept_id) UNIQUE
#  index_academy_learner_concepts_on_concept_id  (concept_id)
#
# Foreign Keys
#
#  fk_rails_...  (concept_id => academy_concepts.id)
#
require "rails_helper"

RSpec.describe Academy::LearnerConcept do
  describe "associations / validations" do
    it "factory builds a valid silhouette record" do
      record = build(:academy_learner_concept)
      expect(record).to be_valid
      expect(record).to be_silhouette
    end

    it "rejects out-of-range levels" do
      record = build(:academy_learner_concept, level: 4)
      expect(record).not_to be_valid
    end

    it "enforces uniqueness on (learner_id, concept_id)" do
      first = create(:academy_learner_concept)
      dup   = build(:academy_learner_concept, learner_id: first.learner_id, concept: first.concept)
      expect(dup).not_to be_valid
    end
  end

  describe "#level_name + predicates" do
    it "exposes named predicates per level" do
      record = build(:academy_learner_concept, level: 2)
      expect(record).to be_recognized
      expect(record.level_name).to eq(:recognized)
    end
  end

  describe ".at_level / .mastered" do
    it "scopes by level" do
      a = create(:academy_learner_concept, level: 1)
      b = create(:academy_learner_concept, level: 3)
      expect(described_class.at_level(1)).to include(a)
      expect(described_class.mastered).to contain_exactly(b)
    end
  end
end
