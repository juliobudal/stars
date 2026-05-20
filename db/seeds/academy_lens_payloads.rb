# frozen_string_literal: true

# Curated lens payloads seeder.
# Reads db/seeds/academy_lens_payloads/<lens_type>/<mission_slug>.json
# and upserts into academy_lens_cache with source='curated'.
#
# Filename convention: `{mission_slug}.json` (mission_slug since v5 is 1:1
# mission↔concept; we resolve concept_id at seed time).
#
# Validates each payload against its lens schema before upsert — a curator
# typo blocks the seed and surfaces the file at fault.
#
# Idempotent: re-running updates payload in place. Unique key:
# (concept_id, lens_type, age_band, locale).

require "json"
require "json-schema"

PAYLOAD_ROOT = Rails.root.join("db/seeds/academy_lens_payloads")
SCHEMA_ROOT  = Rails.root.join("app/services/academy/lens/schemas")

unless PAYLOAD_ROOT.exist?
  puts "↪ Curated payloads: no #{PAYLOAD_ROOT} yet — skipping"
else
  # Tone patterns that curated content must clear — these are the bar
  # the kid-facing voice contract holds itself to. Drift here defeats
  # the curated-static pivot.
  # Tone patterns that curated content must clear. After plan J (2026-05-20),
  # the wonder-hook construction ("Você sabia que..." with a concrete fact) is
  # NO LONGER banned — it's the standard opener of every great science
  # communicator (Sagan, Manual do Mundo, Kurzgesagt). What stays banned:
  # moralization, empty filler, hyper-animation, gratuitous vocatives.
  FORBIDDEN_TONE_PATTERNS = [
    # ── moralização direta ──
    /\breflita sobre\b/i,
    /\bcomo você se sente\b/i,
    /\bé importante (ser|que|fazer|aprender|saber|lembrar|entender)\b/i,
    /\baprenda que\b/i,
    /\ba lição (é|aqui é|aqui)\b/i,
    /\bno fim,? o certo é\b/i,
    /\be foi assim que .*aprendeu\b/i,
    # ── enchimento vazio / TED-talk genérico ──
    /\bdeixa eu te contar uma coisa importante\b/i,
    /\bestudos mostram\b/i,
    /\bmuitos cientistas (acreditam|dizem|pensam)\b/i,
    # ── excesso de animação ──
    /(?:!!+|UAU!|INCRÍVEL!|GALERA!)/,
    # ── vocativo desnecessário ──
    /\b[A-ZÁÉÍÓÚÂÊÔÃÕÇ][a-záéíóúâêôãõç]+, (a|o) [a-zç]+(?:a|o)\b/
    # REMOVED 2026-05-20 (Plan J — wonder-hook liberation):
    #   /\bvocê sabia que\b/i   — the wonder-hook is a feature, not a bug.
    # The judge (when LLM rolls again) still gates "vacuidade do hook";
    # a "você sabia que" must be followed by a concrete fact, not fluff.
  ].freeze

  def self.collect_strings(node, acc = [])
    case node
    when Hash  then node.each_value { |v| collect_strings(v, acc) }
    when Array then node.each { |v| collect_strings(v, acc) }
    when String then acc << node
    end
    acc
  end

  def self.tone_violations(payload, forbidden_terms)
    text = collect_strings(payload).join(" \n ")
    violations = []
    FORBIDDEN_TONE_PATTERNS.each do |re|
      m = text.match(re)
      violations << "tone: '#{m[0]}'" if m
    end
    forbidden_terms.each do |term|
      next if term.length < 3
      re = /#{Regexp.escape(term)}/i
      m = text.match(re)
      violations << "concept-forbidden: '#{m[0]}'" if m
    end
    violations
  end

  mission_by_slug = ::Academy::Mission.includes(:concept).index_by(&:slug)
  concept_by_slug = ::Academy::Concept.all.index_by(&:slug)
  schemas = {}
  upserted = 0
  skipped = 0
  failed  = []
  tone_failed = []
  readability_failed = []
  readability_warned = []

  # Readability gating (Plan E). FRE-PT target for kid (7-12 years old):
  #   >= 60 ok  ·  50..60 warn  ·  < 50 block
  # Block raises on seed (so prod never ships unreadable curated content).
  # READABILITY_STRICT=0 demotes block→warn for incremental cleanup runs.
  READABILITY_STRICT = ENV.fetch("READABILITY_STRICT", "1") == "1"

  # Filename resolution: a file is keyed first by mission_slug (the v5
  # convention — every mission ships its own narrative/scientific/etc).
  # If no mission matches, fall back to concept_slug so dormant concepts
  # (no published mission yet) can carry curated payloads ready to be
  # referenced when a mission is eventually authored against them.
  Dir.glob(PAYLOAD_ROOT.join("*", "*.json")).each do |file|
    lens_type    = File.basename(File.dirname(file))
    file_slug    = File.basename(file, ".json")
    # Filename convention with interest variant: `<mission_or_concept_slug>.<interest_key>.json`
    # Default (no variant) stays as `<slug>.json`.
    base_slug, interest_key =
      if file_slug.count(".").positive?
        file_slug.split(".", 2)
      else
        [file_slug, nil]
      end
    mission      = mission_by_slug[base_slug]
    concept      = mission&.concept || concept_by_slug[base_slug]
    forbidden    = (mission&.concept || concept)&.forbidden_terms_list || []

    unless concept
      skipped += 1
      puts "  ⚠ skip #{lens_type}/#{file_slug}.json — no mission or concept matches"
      next
    end

    payload = JSON.parse(File.read(file))
    schema_path = SCHEMA_ROOT.join("#{lens_type}.json")
    unless schemas[lens_type]
      raw = JSON.parse(File.read(schema_path))
      raw.delete("$schema")
      schemas[lens_type] = raw
    end

    errors = JSON::Validator.fully_validate(schemas[lens_type], payload, version: :draft4)
    if errors.any?
      failed << [file, errors]
      next
    end

    tone = tone_violations(payload, forbidden)
    if tone.any?
      tone_failed << [file, tone]
      next
    end

    # Join with ". " so payload leaves (e.g. analogy_bridge mapping labels)
    # that have no terminator each register as their own sentence — without
    # this, the FRE-PT formula collapses (one giant "sentence", hundreds of
    # words) and good content scores absurdly low.
    readability = ::Academy::Llm::Readability.analyze(
      collect_strings(payload).map { |s| s.strip.sub(/[.!?…]+\z/, "") }
                              .reject(&:empty?).join(". ")
    )
    if readability.block?
      readability_failed << [file, readability.score]
      next if READABILITY_STRICT
    elsif readability.warn?
      readability_warned << [file, readability.score]
    end

    key = {
      concept_id: concept.id,
      lens_type: lens_type,
      age_band: "kid",
      locale: "pt-BR",
      interest_key: interest_key
    }

    row = ::Academy::LensCache.find_or_initialize_by(key)
    row.assign_attributes(
      payload: payload,
      source: "curated",
      generated_at: Time.current,
      quality_flagged: false
    )
    row.save!
    upserted += 1
  end

  puts "↪ Curated payloads: #{upserted} upserted, #{skipped} skipped, " \
       "#{failed.size} schema-failed, #{tone_failed.size} tone-failed, " \
       "#{readability_failed.size} readability-blocked, " \
       "#{readability_warned.size} readability-warned"
  if failed.any?
    puts "  ✘ schema failures:"
    failed.each { |f, e| puts "    - #{f}: #{e.first}" }
  end
  if tone_failed.any?
    puts "  ✘ tone/forbidden-term violations:"
    tone_failed.each { |f, v| puts "    - #{f}: #{v.join(' · ')}" }
  end
  if readability_warned.any?
    puts "  ⚠ readability warn (FRE 50-60, accepted):"
    readability_warned.each { |f, s| puts "    - #{f}: FRE #{s}" }
  end
  if readability_failed.any?
    label = READABILITY_STRICT ? "✘ readability block (FRE < 50)" :
                                 "⚠ readability block (FRE < 50, demoted by READABILITY_STRICT=0)"
    puts "  #{label}:"
    readability_failed.each { |f, s| puts "    - #{f}: FRE #{s}" }
  end
  if failed.any? || tone_failed.any? || (READABILITY_STRICT && readability_failed.any?)
    raise "Curated payload validation failed"
  end
end
