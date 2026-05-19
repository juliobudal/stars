# frozen_string_literal: true

# Academy v4 — orchestrates the v4-specific seeds:
#   1) story_choice missions (db/seeds/academy_stories.rb)
#   2) typed concept_edges (curated mapping in lib/tasks/academy_edges.rake)
#   3) Pokédex backfill from any existing completed MissionProgress
#
# Idempotent. Loaded from db/seeds/academy.rb at the tail.

puts ""
puts "── Academy v4 seeds ────────────────────────────────────"

# 0. discovery missions — recalibration to v4 quality bar + new pílulas
load Rails.root.join("db/seeds/academy_v4_missions.rb")

# 1. story_choice missions
load Rails.root.join("db/seeds/academy_stories.rb")

# 2. typed concept_edges — re-tag known pairs (matches the curated map in
#    lib/tasks/academy_edges.rake but copied inline so seed has no rake dep).
CURATED_TYPED_EDGES = {
  %w[dopamina recompensa-variavel]        => "generalizes",
  %w[recompensa-variavel habito-loop]      => "composes_with",
  %w[dopamina ultraprocessados]            => "manifests_in",
  %w[dopamina algoritmo-recomendacao]      => "manifests_in",
  %w[sistema-1-vs-2 vies-confirmacao]      => "predicts",
  %w[habito-loop regra-dos-2-min]          => "composes_with",
  %w[gratificacao-tardia juros-compostos]  => "predicts",
  %w[escassez-percebida prova-social]      => "composes_with",
  %w[melatonina sono-consolidacao]         => "composes_with",
  %w[glicose-pico ultraprocessados]        => "manifests_in"
}.freeze

slug_to_id = ::Academy::Concept.pluck(:slug, :id).to_h
edges_updated = 0
CURATED_TYPED_EDGES.each do |(from_slug, to_slug), type|
  from_id = slug_to_id[from_slug]
  to_id   = slug_to_id[to_slug]
  next unless from_id && to_id

  edge = ::Academy::ConceptEdge.find_by(from_concept_id: from_id, to_concept_id: to_id)
  next unless edge
  next if edge.edge_type == type

  edge.update!(edge_type: type)
  edges_updated += 1
end
puts "✓ typed concept_edges upserted: #{edges_updated}"

# 3. Pokédex backfill — replay completed missions if any exist. No-op on
#    fresh setups.
if ::Academy::MissionProgress.where(status: %i[completed mastered]).exists?
  result = ::Academy::Pokedex::Backfill.call
  if result.success?
    puts "✓ Pokédex backfill: #{result.data[:applied]} applied · #{result.data[:failed]} failed"
  else
    warn "  ⚠ Pokédex backfill failed: #{result.error}"
  end
else
  puts "↪ Pokédex backfill skipped (no completed missions in DB)"
end

puts "── Academy v4 seeds done ───────────────────────────────"
