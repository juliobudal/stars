# frozen_string_literal: true

module Academy
  # A persistent "Card de Descoberta" minted when a learner completes a
  # mission in Academy v2. Lives in the kid's Atlas — substitutes the
  # ephemeral v1 celebration screen with a collectible artifact.
  #
  # One card per (learner, mission). Idempotent — `MintAfterMission` does
# == Schema Information
#
# Table name: academy_discovery_cards
#
#  id                                                               :bigint           not null, primary key
#  application(1-sentence concrete application)                     :text
#  central_insight(Copied snapshot of mission insight at mint time) :text
#  headline(1-line sacada compressed)                               :string(180)      not null
#  illustration_key(Icon/illustration to render)                    :string
#  kind(mission_card | trail_theory | virtue_sighting)              :string           default("mission_card"), not null
#  minted_at                                                        :datetime         not null
#  source(Author/tradition (optional, when applicable))             :string
#  created_at                                                       :datetime         not null
#  updated_at                                                       :datetime         not null
#  learner_id                                                       :bigint           not null
#  mission_id                                                       :bigint           not null
#
# Indexes
#
#  idx_academy_cards_learner_time               (learner_id,minted_at)
#  idx_academy_cards_unique                     (learner_id,mission_id) UNIQUE
#  idx_academy_discovery_cards_learner_kind     (learner_id,kind)
#  index_academy_discovery_cards_on_mission_id  (mission_id)
#
# Foreign Keys
#
#  fk_rails_...  (mission_id => academy_missions.id)
#
  # a find_or_create so re-running mission finalization is safe.
  class DiscoveryCard < ApplicationRecord
    self.table_name = "academy_discovery_cards"

    belongs_to :mission, class_name: "Academy::Mission"
    has_many :recall_reviews, class_name: "Academy::RecallReview",
             foreign_key: :card_id, dependent: :destroy

    validates :learner_id, presence: true
    validates :learner_id, uniqueness: { scope: :mission_id }
    validates :headline, presence: true, length: { maximum: 180 }
    validates :minted_at, presence: true

    scope :for_learner, ->(learner_id) {
      where(learner_id: learner_id).order(minted_at: :desc)
    }
  end
end
