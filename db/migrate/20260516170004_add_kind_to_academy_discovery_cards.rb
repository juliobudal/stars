# frozen_string_literal: true

# Academy v4 — Discovery cards now come in 3 kinds (rarity tiers in disguise):
#   mission_card     # default — minted at the end of a mission
#   trail_theory     # rare — kid synthesized a trail-wide insight
#   virtue_sighting  # rarer — pinned moment of practiced virtue
class AddKindToAcademyDiscoveryCards < ActiveRecord::Migration[8.1]
  def change
    add_column :academy_discovery_cards, :kind, :string,
               null: false,
               default: "mission_card",
               comment: "mission_card | trail_theory | virtue_sighting"

    add_index :academy_discovery_cards, [ :learner_id, :kind ],
              name: "idx_academy_discovery_cards_learner_kind"
  end
end
