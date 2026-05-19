# frozen_string_literal: true

# Authoring tools for curated lens payloads.
# See .planning/designs/academy-curated-static-pivot.md.
#
# Workflow per payload:
#   1. `rake academy:lens:draft[mission_slug,lens_type]` — LLM drafts +
#      Judge validates, writes to tmp/drafts/.
#   2. Curator edits prose in tmp/drafts/...
#   3. Move to db/seeds/academy_lens_payloads/<lens_type>/<mission_slug>.json
#   4. `make seed` upserts as source='curated'.
#
# `rake academy:lens:draft_trail[trail_slug]` drafts every (mission × lens)
# combo for a trail — useful for pilot scope.

namespace :academy do
  namespace :lens do
    DRAFT_ROOT = Rails.root.join("tmp/drafts")
    SEED_ROOT  = Rails.root.join("db/seeds/academy_lens_payloads")

    desc "Draft a single payload — args: mission_slug, lens_type"
    task :draft, %i[mission_slug lens_type] => :environment do |_, args|
      slug = args[:mission_slug] or abort("mission_slug required")
      lens = args[:lens_type]    or abort("lens_type required")
      draft_one(slug, lens.to_sym)
    end

    desc "Draft every (mission × lens) for a trail — arg: trail_slug"
    task :draft_trail, %i[trail_slug] => :environment do |_, args|
      trail_slug = args[:trail_slug] or abort("trail_slug required")
      trail = ::Academy::Trail.find_by!(slug: trail_slug)
      scope_path = Rails.root.join(".planning/designs/atencao-pilot-scope.md")
      puts "Drafting all lenses for trail '#{trail.slug}'."
      puts "(Scope reference: #{scope_path.relative_path_from(Rails.root)})"

      trail.missions.active.find_each do |mission|
        ::Academy::Lens::Catalog.types.each do |lens|
          draft_one(mission.slug, lens, mission: mission)
        end
      end
    end

    desc "List missions with their curated payload coverage (which lenses done)"
    task coverage: :environment do
      rows = ::Academy::Mission.includes(:concept).map do |m|
        next unless m.concept_id
        done = ::Academy::LensCache.curated.where(concept_id: m.concept_id).pluck(:lens_type)
        { slug: m.slug, done: done.sort, total: done.size }
      end.compact

      rows.sort_by { |r| -r[:total] }.each do |r|
        puts format("%-40s %d/8  %s", r[:slug], r[:total], r[:done].join(","))
      end
    end

    def draft_one(mission_slug, lens_type, mission: nil)
      mission ||= ::Academy::Mission.includes(:concept).find_by(slug: mission_slug)
      unless mission&.concept_id
        puts "  ✘ #{mission_slug}/#{lens_type} — mission or concept missing"
        return
      end

      out_dir = DRAFT_ROOT.join(lens_type.to_s)
      out_dir.mkpath
      out_file = out_dir.join("#{mission_slug}.json")

      if out_file.exist?
        puts "  ↪ skip #{lens_type}/#{mission_slug}.json — draft already exists"
        return
      end

      gen_klass = ::Academy::Lens::Generators.for(lens_type)
      gen = gen_klass.new(concept: mission.concept, age_band: "kid", locale: "pt-BR")
      result = gen.call

      unless result.success?
        puts "  ✘ #{lens_type}/#{mission_slug} — generator failed: #{result.error}"
        return
      end

      payload = result.data[:payload]
      verdict = result.data[:judge_verdict]
      out_file.write(JSON.pretty_generate(payload))
      puts "  ✓ #{lens_type}/#{mission_slug} → #{out_file.relative_path_from(Rails.root)}  (judge=#{verdict || 'skipped'})"
    end
  end
end
