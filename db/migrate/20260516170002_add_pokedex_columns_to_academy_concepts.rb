# frozen_string_literal: true

# Academy v4 — Pokédex visual identity for concepts.
# The silhouette and color keys are content-team-managed asset/token names,
# not raw hex/paths.
class AddPokedexColumnsToAcademyConcepts < ActiveRecord::Migration[8.1]
  def change
    add_column :academy_concepts, :pokedex_silhouette_key, :string,
               comment: "Asset name in app/assets/images/academy/pokedex/ (svg)"
    add_column :academy_concepts, :pokedex_color_key, :string,
               comment: "Design token name (e.g. 'pokedex-mind', 'pokedex-body')"
  end
end
