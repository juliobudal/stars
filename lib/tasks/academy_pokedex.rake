# frozen_string_literal: true

# Pokédex (v4) rake tasks. Live alongside `lib/tasks/academy.rake`.
namespace :academy do
  namespace :pokedex do
    desc "Assign pokedex_color_key + pokedex_silhouette_key to all concepts (v4)"
    task assign_keys: :environment do
      before = ::Academy::Concept.where.not(pokedex_color_key: nil).count
      load Rails.root.join("db/seeds/academy_pokedex_keys.rb")
      after = ::Academy::Concept.where.not(pokedex_color_key: nil).count
      puts "Pokédex keys assigned — concepts with color_key: #{before} → #{after}"
    end

    desc "Replay completed missions to populate academy_learner_concepts (v4)"
    task backfill: :environment do
      learner_ids = ENV["LEARNER_IDS"]&.split(",")&.map(&:to_i)
      result = ::Academy::Pokedex::Backfill.call(learner_ids: learner_ids)

      if result.success?
        puts "Pokédex backfill complete — applied: #{result.data[:applied]}, failed: #{result.data[:failed]}"
      else
        warn "Pokédex backfill failed: #{result.error}"
        exit 1
      end
    end

    desc "Re-derive LearnerConcept.level using v5 ladder semantics. Set DRY_RUN=1 to report deltas only."
    task reladder: :environment do
      dry = ENV["DRY_RUN"].to_s == "1"
      up = down = unchanged = 0

      ::Academy::LearnerConcept.find_each do |record|
        new_level = ::Academy::Pokedex::Reladder.compute_level_for(
          learner_id: record.learner_id, concept_id: record.concept_id
        )
        case new_level <=> record.level
        when 1
          up += 1
          record.update_columns(level: new_level) unless dry
        when -1
          down += 1
          # Monotonic invariant — log but do NOT downgrade automatically.
          warn "[reladder] would downgrade learner=#{record.learner_id} concept=#{record.concept_id} #{record.level}→#{new_level}"
        else
          unchanged += 1
        end
      end

      mode = dry ? "DRY RUN" : "APPLIED"
      puts "[#{mode}] reladder: #{up} up · #{down} would-downgrade (skipped) · #{unchanged} unchanged"
    end
  end
end
