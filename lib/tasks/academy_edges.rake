# frozen_string_literal: true

# Backfill v4 typed `edge_type` on existing academy_concept_edges.
# Strategy: a curated mapping of well-known concept pairs lives here.
# Pairs not in the mapping stay as `relates_to` (the migration default).
# Edit CURATED_EDGES to upgrade more pairs.
namespace :academy do
  namespace :concept_edges do
    # Curated against the actual edges seeded in db/seeds/academy.rb
    # (verified via Academy::ConceptEdge enumeration 2026-05-19).
    # Pairs absent here remain as `relates_to` (the default).
    CURATED_EDGES = {
      # %w[from_slug to_slug] => "edge_type"

      # mechanisms manifesting in concrete phenomena
      %w[dopamina recompensa-imediata]         => "manifests_in",
      %w[glicose-pico dopamina]                => "manifests_in",
      %w[ultraprocessados recompensa-imediata] => "manifests_in",
      %w[sinal-corporal homeostase]            => "manifests_in",

      # category-level relationships
      %w[dopamina recompensa-variavel]         => "generalizes",
      %w[atencao foco]                         => "generalizes",

      # systems built from sub-components
      %w[habito-loop regra-dos-2-min]          => "composes_with",
      %w[habito-loop neuroplasticidade]        => "composes_with",
      %w[foco deep-work]                       => "composes_with",
      %w[deep-work consistencia]               => "composes_with",
      %w[sono-consolidacao melatonina]         => "composes_with",
      %w[sono-consolidacao memoria-reconstrutiva] => "composes_with",
      %w[recompensa-variavel atencao]          => "composes_with",
      %w[prova-social escassez-percebida]      => "composes_with",
      %w[pensamento-computacional decomposicao] => "composes_with",
      %w[pensamento-computacional sistemas]    => "composes_with",
      %w[feedback-loop sistemas]               => "composes_with",
      %w[empatia escuta-ativa]                 => "composes_with",
      %w[escuta-ativa comunicacao]             => "composes_with",

      # knowing A predicts behavior/risk in B
      %w[sistema-1-vs-2 ceticismo]             => "predicts",
      %w[vies-confirmacao ceticismo]           => "predicts",
      %w[memoria-reconstrutiva ceticismo]      => "predicts",
      %w[atencao switch-cost]                  => "predicts",
      %w[probabilidade ceticismo]              => "predicts",
      %w[consistencia habito-loop]             => "predicts",
      %w[habito-loop identidade]               => "predicts",
      %w[virtude-habito identidade]            => "predicts",
      %w[juros-compostos gratificacao-tardia]  => "predicts",

      # one is a refined/specialized form of the other
      %w[escassez-percebida escassez]          => "specializes",
      %w[recompensa-imediata gratificacao-tardia] => "contrasts_with"
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
