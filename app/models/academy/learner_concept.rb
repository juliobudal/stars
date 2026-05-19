# frozen_string_literal: true

module Academy
  # Pokédex entry — one row per (learner, concept). Level (0..3) is driven
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
#  transfer_count                                                            :integer          default(0), not null
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
  # by Academy::Pokedex::Advance and never regresses.
  class LearnerConcept < ApplicationRecord
    self.table_name = "academy_learner_concepts"

    belongs_to :concept, class_name: "Academy::Concept"

    LEVELS = { silhouette: 0, spotted: 1, recognized: 2, mastered: 3 }.freeze

    validates :learner_id, presence: true
    validates :level, presence: true, inclusion: { in: LEVELS.values }
    validates :learner_id, uniqueness: { scope: :concept_id }

    scope :for_learner, ->(learner_id) { where(learner_id: learner_id) }
    scope :at_level,    ->(lvl) { where(level: lvl) }
    scope :mastered,    -> { where(level: LEVELS[:mastered]) }
    scope :recognized_plus, -> { where(level: LEVELS[:recognized]..) }

    def silhouette? = level.zero?
    def spotted?    = level == LEVELS[:spotted]
    def recognized? = level == LEVELS[:recognized]
    def mastered?   = level == LEVELS[:mastered]

    def level_name
      LEVELS.key(level)
    end
  end
end
