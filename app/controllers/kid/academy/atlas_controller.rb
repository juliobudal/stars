# frozen_string_literal: true

class Kid::Academy::AtlasController < Kid::Academy::BaseController
  CATEGORY_LABELS = {
    "cognitivo"   => "Como a mente funciona",
    "cientifico"  => "Pensar direito",
    "social"      => "Gente",
    "financeiro"  => "Dinheiro",
    "saude"       => "Corpo",
    "virtude"     => "Caráter",
    "tecnologia"  => "Máquinas e código"
  }.freeze

  CATEGORY_ORDER = %w[cognitivo saude social virtude financeiro tecnologia cientifico].freeze

  def index
    learner_id = current_learner.id

    @concepts_by_category = ::Academy::Concept.active.group_by(&:category)

    learner_concepts = ::Academy::LearnerConcept
                         .for_learner(learner_id)
                         .index_by(&:concept_id)
    @learner_concepts = learner_concepts

    # v4 — concepts that evolved in the last ~60s pulse on page load.
    fresh_window = 60.seconds.ago
    @just_evolved_concept_ids = learner_concepts.values.select do |lc|
      (lc.evolved_to_2_at.present? && lc.evolved_to_2_at >= fresh_window) ||
        (lc.evolved_to_3_at.present? && lc.evolved_to_3_at >= fresh_window)
    end.map(&:concept_id).to_set

    @counts = {
      total: @concepts_by_category.values.flatten.size,
      sighted: learner_concepts.values.count { |lc| lc.level >= 1 },
      mastered: learner_concepts.values.count(&:mastered?),
      evolving: learner_concepts.values.count { |lc| lc.level.between?(1, 2) }
    }

    @recent_cards = ::Academy::DiscoveryCard
                      .for_learner(learner_id)
                      .includes(mission: :subject)
                      .limit(6)
  end
end
