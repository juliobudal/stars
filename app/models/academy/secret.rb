# frozen_string_literal: true

module Academy
  # A bonus pílula (or pure narrative reveal) unlocked by a condition on the
  # learner's progress. Different from regular missions because it doesn't
  # appear in trail lists — it surfaces as an "ALGO NOVO" card when the
  # == Schema Information
  #
  # Table name: academy_secrets
  #
  #  id                                                         :bigint           not null, primary key
  #  active                                                     :boolean          default(TRUE), not null
  #  kind(0=cards_in_subject, 1=cards_total, 2=challenge_ratio) :integer          default("cards_in_subject"), not null
  #  position                                                   :integer          default(0), not null
  #  rule(e.g. { subject_slug: 'mente-forte', threshold: 5 })   :jsonb            not null
  #  slug                                                       :string           not null
  #  teaser(Mysterious hint shown when locked)                  :text
  #  title                                                      :string           not null
  #  created_at                                                 :datetime         not null
  #  updated_at                                                 :datetime         not null
  #  mission_id(Optional bonus pílula tied to this secret)      :bigint
  #
  # Indexes
  #
  #  index_academy_secrets_on_mission_id  (mission_id)
  #  index_academy_secrets_on_slug        (slug) UNIQUE
  #
  # Foreign Keys
  #
  #  fk_rails_...  (mission_id => academy_missions.id)
  #
  # rule is satisfied.
  class Secret < ApplicationRecord
    self.table_name = "academy_secrets"

    enum :kind, {
      cards_in_subject: 0,
      cards_total:      1,
      challenge_ratio:  2
    }, default: :cards_in_subject

    belongs_to :mission, class_name: "Academy::Mission", optional: true
    has_many :unlocks, class_name: "Academy::SecretUnlock",
             foreign_key: :secret_id, dependent: :destroy

    validates :slug, :title, presence: true
    validates :slug, uniqueness: true

    scope :active, -> { where(active: true).order(:position, :id) }

    def to_param = slug
  end
end
