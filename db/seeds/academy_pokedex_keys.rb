# frozen_string_literal: true

# Academy v4 — Pokédex visual keys.
# Idempotent. Runs after db/seeds/academy_concepts.rb.
#
# Strategy: hybrid asset model.
#   - Every concept gets a color_key (1 of 7 categories) — Atlas tints
#     silhouette/fill/glow from --academy-pokedex-{color_key}.
#   - Hero concepts get a silhouette_key (custom asset name). Non-hero
#     concepts leave silhouette_key NULL, so the view falls back to the
#     category glyph: app/assets/images/academy/pokedex/_{color_key}.svg

POKEDEX_CATEGORY_BY_SLUG = {
  # cognitivo
  "dopamina"              => "cognitivo",
  "recompensa-variavel"   => "cognitivo",
  "recompensa-imediata"   => "cognitivo",
  "gratificacao-tardia"   => "cognitivo",
  "habito-loop"           => "cognitivo",
  "identidade"            => "cognitivo",
  "atencao"               => "cognitivo",
  "foco"                  => "cognitivo",
  "switch-cost"           => "cognitivo",
  "deep-work"             => "cognitivo",
  "sistema-1-vs-2"        => "cognitivo",
  "vies-confirmacao"      => "cognitivo",
  "memoria-reconstrutiva" => "cognitivo",
  "ceticismo"             => "cognitivo",
  "neuroplasticidade"     => "cognitivo",
  "regra-dos-2-min"       => "cognitivo",
  "criatividade"          => "cognitivo",
  # saude
  "sono-consolidacao"     => "saude",
  "melatonina"            => "saude",
  "homeostase"            => "saude",
  "glicose-pico"          => "saude",
  "ultraprocessados"      => "saude",
  "consistencia"          => "saude",
  "sinal-corporal"        => "saude",
  # social
  "prova-social"          => "social",
  "escassez-percebida"    => "social",
  "empatia"               => "social",
  "escuta-ativa"          => "social",
  "comunicacao"           => "social",
  "palavra-dada"          => "social",
  "confianca"             => "social",
  "pausa-estrategica"     => "social",
  "feedback-formativo"    => "social",
  # virtude
  "virtude-habito"        => "virtude",
  "coragem"               => "virtude",
  "honestidade"           => "virtude",
  "gratidao"              => "virtude",
  # financeiro
  "juros-compostos"       => "financeiro",
  "tradeoff"              => "financeiro",
  "escassez"              => "financeiro",
  "pagar-se-primeiro"     => "financeiro",
  # tecnologia
  "pensamento-computacional" => "tecnologia",
  "probabilidade"            => "tecnologia",
  "sistemas"                 => "tecnologia",
  "algoritmo-recomendacao"   => "tecnologia",
  "aprendizado-ativo"        => "tecnologia",
  # cientifico
  "decomposicao"          => "cientifico",
  "estrategia"            => "cientifico",
  "decisao-rapida"        => "cientifico",
  "feedback-loop"         => "cientifico",
  "causa-e-efeito"        => "cientifico",
  "pareto"                => "cientifico",
  "5-porques"             => "cientifico"
}.freeze

# Hero concepts get a dedicated silhouette. Filename = "{slug}.svg" in
# app/assets/images/academy/pokedex/. Choose by mission frequency +
# identity weight — these are the "starter Pokémon" of the Atlas.
POKEDEX_HERO_SLUGS = %w[
  dopamina
  recompensa-variavel
  foco
  sistema-1-vs-2
  neuroplasticidade
  sono-consolidacao
  glicose-pico
  empatia
  palavra-dada
  coragem
  honestidade
  juros-compostos
  algoritmo-recomendacao
  pareto
].freeze

updated = 0
missing = []

POKEDEX_CATEGORY_BY_SLUG.each do |slug, color_key|
  concept = ::Academy::Concept.find_by(slug: slug)
  if concept.nil?
    missing << slug
    next
  end
  silhouette_key = POKEDEX_HERO_SLUGS.include?(slug) ? slug : nil
  concept.update!(
    pokedex_color_key: color_key,
    pokedex_silhouette_key: silhouette_key
  )
  updated += 1
end

puts "[academy/pokedex_keys] updated #{updated}/#{POKEDEX_CATEGORY_BY_SLUG.size} concepts"
puts "[academy/pokedex_keys] missing slugs: #{missing.join(', ')}" if missing.any?
