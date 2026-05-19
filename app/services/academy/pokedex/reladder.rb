# frozen_string_literal: true

module Academy
  module Pokedex
    # Pure recompute helper used by `academy:pokedex:reladder` rake task.
    # Mirrors the level decision logic in Pokedex::Advance but operates on
    # (learner_id, concept_id) pairs without writing.
    module Reladder
      module_function

      def compute_level_for(learner_id:, concept_id:)
        completions = ::Academy::MissionProgress
                        .joins(:mission)
                        .where(academy_missions: { concept_id: concept_id })
                        .where(learner_id: learner_id, status: %i[completed mastered])

        completion_count = completions.count
        subject_count    = completions.distinct.count("academy_missions.subject_id")
        visit_count      = ::Academy::LearnerLensVisit
                             .where(learner_id: learner_id, concept_id: concept_id)
                             .count

        return 3 if completion_count >= 2 && subject_count >= 2
        return 2 if completion_count >= 1
        return 1 if visit_count >= 1

        0
      end
    end
  end
end
