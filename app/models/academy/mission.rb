# frozen_string_literal: true

# == Schema Information
#
# Table name: academy_missions
#
#  id                                                                                                              :bigint           not null, primary key
#  active                                                                                                          :boolean          default(TRUE), not null
#  angle(Specific unique angle for this mission)                                                                   :text
#  central_insight(The 'se X, então Y' takeaway the kid should keep)                                               :string(240)
#  challenge_observable(What the kid should notice after doing it)                                                 :string
#  challenge_prompt(Mini-desafio comportamental that anchors the lesson)                                           :text
#  challenge_when(When to do the challenge: hoje | esta-semana)                                                    :string
#  curiosity_facts                                                                                                 :jsonb            not null
#  framework(Didactic frame: socratic | story | metaphor | case | thought_experiment | paradox | historical_scene) :string
#  hook(Short mysterious teaser to entice the kid)                                                                 :string
#  illustration_key(Icon/illustration slug the discovery card uses)                                                :string
#  learning_objective                                                                                              :text             not null
#  order_in_subject                                                                                                :integer          default(0), not null
#  points_reward                                                                                                   :integer          default(25), not null
#  position_in_trail                                                                                               :integer
#  sacada(The 1-line counter-intuitive insight (the 'pílula' itself))                                              :text
#  slug                                                                                                            :string           not null
#  source(Author(s)/tradition/study the pílula distills (e.g. 'Carnegie', 'Marco Aurélio', 'Provérbios'))          :string
#  title                                                                                                           :string           not null
#  created_at                                                                                                      :datetime         not null
#  updated_at                                                                                                      :datetime         not null
#  concept_id                                                                                                      :bigint           not null
#  subject_id                                                                                                      :bigint           not null
#  trail_id                                                                                                        :bigint
#
# Indexes
#
#  index_academy_missions_on_concept_id                       (concept_id)
#  index_academy_missions_on_framework                        (framework)
#  index_academy_missions_on_source                           (source)
#  index_academy_missions_on_subject_id                       (subject_id)
#  index_academy_missions_on_subject_id_and_order_in_subject  (subject_id,order_in_subject)
#  index_academy_missions_on_subject_id_and_slug              (subject_id,slug) UNIQUE
#  index_academy_missions_on_trail_id                         (trail_id)
#
# Foreign Keys
#
#  fk_rails_...  (concept_id => academy_concepts.id)
#  fk_rails_...  (subject_id => academy_subjects.id)
#  fk_rails_...  (trail_id => academy_trails.id)
#
module Academy
  class Mission < ApplicationRecord
    self.table_name = "academy_missions"

    belongs_to :subject, class_name: "Academy::Subject", inverse_of: :missions
    belongs_to :trail, class_name: "Academy::Trail", inverse_of: :missions, optional: true
    # v5: 1:1 missão↔conceito (substitui M:N via aula_concepts).
    belongs_to :concept, class_name: "Academy::Concept", optional: true
    has_many :progresses, class_name: "Academy::MissionProgress",
             foreign_key: :mission_id, dependent: :destroy
    has_many :discovery_cards, class_name: "Academy::DiscoveryCard",
             foreign_key: :mission_id, dependent: :destroy

    validates :slug, :title, :learning_objective, presence: true
    validates :slug, uniqueness: { scope: :subject_id }
    validates :central_insight, length: { maximum: 240 }, allow_blank: true
    # Coverage check only runs in :publish context — it would otherwise
    # break ordered seeding (missions are saved BEFORE the lens payload
    # seeder loads). Run `Academy::Mission.where(active: true).find_each
    # { |m| m.valid?(:publish) || raise(...) }` from the seed (see
    # db/seeds/academy.rb post-seed audit) or from CI to catch drift.
    validate :concept_must_have_curated_kid_payload, on: :publish

    scope :active, -> { where(active: true).order(:order_in_subject) }
    scope :in_trail_order, -> { order(Arel.sql("position_in_trail NULLS LAST"), :order_in_subject) }
    scope :by_source, ->(value) { where(source: value) }
    scope :by_framework, ->(value) { where(framework: value) }

    def to_param = slug

    def progress_for(learner_id)
      progresses.find_or_initialize_by(learner_id: learner_id)
    end

    # True when the mission carries a v2 mini-desafio (challenge_prompt
    # is set). Legacy v1 missions return false.
    def challenge?
      challenge_prompt.present?
    end

    # Short author label for display. The seed stores rich source text like
    # "Dale Carnegie (Como Fazer Amigos…) — princípio 1" or
    # "Marco Aurélio (Meditações) + Epicteto". We keep only the first author
    # for chips/badges.
    def source_label
      return nil if source.blank?

      source.split(/[+(]/).first.to_s.strip.presence
    end

    private

    # Block publishing a mission whose concept has no curated kid payload —
    # otherwise ChooseNext would return :no_curated_content and the kid
    # would hit a redirect loop on first open.
    def concept_must_have_curated_kid_payload
      return if concept_id.blank?
      # Inactive missions can ship without coverage — they're hidden.
      return unless active?

      has_payload = Academy::LensCache.curated.servable
                      .where(concept_id: concept_id, age_band: "kid", locale: "pt-BR")
                      .exists?
      return if has_payload

      errors.add(:concept, "ainda não tem aula curada — não pode publicar")
    end
  end
end
