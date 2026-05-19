# frozen_string_literal: true

# Backfill v4 typed `edge_type` on existing academy_concept_edges.
# Strategy: a curated mapping of well-known concept pairs lives here.
# Pairs not in the mapping stay as `relates_to` (the migration default).
# Edit CURATED_EDGES to upgrade more pairs.
namespace :academy do
  namespace :concept_edges do
    CURATED_EDGES = {
      # %w[from_slug to_slug] => "edge_type"
      %w[dopamina recompensa-variavel]   => "generalizes",
      %w[recompensa-variavel habito-loop] => "composes_with",
      %w[dopamina ultraprocessados]      => "manifests_in",
      %w[dopamina algoritmo-recomendacao] => "manifests_in",
      %w[sistema-1-vs-2 vies-confirmacao] => "predicts",
      %w[habito-loop regra-dos-2-min]    => "composes_with",
      %w[gratificacao-tardia juros-compostos] => "predicts",
      %w[escassez-percebida prova-social] => "composes_with",
      %w[melatonina sono-consolidacao]   => "composes_with",
      %w[glicose-pico ultraprocessados]  => "manifests_in"
    }.freeze

    desc "Backfill edge_type on academy_concept_edges using a curated mapping"
    task backfill: :environment do
      slug_to_id = ::Academy::Concept.pluck(:slug, :id).to_h
      updated = 0
      skipped = 0

      CURATED_EDGES.each do |(from_slug, to_slug), type|
        from_id = slug_to_id[from_slug]
        to_id   = slug_to_id[to_slug]
        unless from_id && to_id
          skipped += 1
          next
        end

        edge = ::Academy::ConceptEdge.find_by(from_concept_id: from_id, to_concept_id: to_id)
        if edge
          edge.update!(edge_type: type)
          updated += 1
        else
          skipped += 1
        end
      end

      puts "edge_type backfill: #{updated} updated, #{skipped} skipped (pair missing)"
    end
  end
end
