# frozen_string_literal: true

namespace :academy do
  namespace :illustrations do
    desc <<~DESC
      Generates webp illustrations for academy_lens_cache rows that carry
      an `illustration_hint`. Options (via ENV):
        FORCE=1                regenerate even when up to date
        ONLY=slug1,slug2       restrict to the listed concept slugs
        DRY_RUN=1              report only — no API calls, no disk writes
        MODEL=...              override Academy.config.image_model for this run
    DESC
    task generate: :environment do
      force   = ENV["FORCE"].to_s == "1"
      dry_run = ENV["DRY_RUN"].to_s == "1"
      only    = ENV["ONLY"].to_s.split(",").map(&:strip).reject(&:empty?)
      model   = ENV["MODEL"].to_s.strip

      if !dry_run && Academy.config.openrouter_api_key.to_s.length < 9
        abort "OPENROUTER_API_KEY ausente. Defina em .env antes de rodar."
      end

      Academy.config.image_model = model if model.present?

      scope = Academy::LensCache.where("(payload->>'illustration_hint') IS NOT NULL")
      scope = scope.joins(:concept).where(academy_concepts: { slug: only }) if only.any?
      rows = scope.includes(:concept).to_a

      if rows.empty?
        puts "No lens_cache rows with `illustration_hint` matched the filter."
        next
      end

      total = rows.size
      style = Academy::Illustrations::PromptComposer::STYLE_VERSION
      output_dir = Academy::Illustrations::Generate::OUTPUT_DIR

      if dry_run
        puts "DRY_RUN — would consider #{total} rows under style '#{style}'."
        puts "Estimated upper bound: $#{format('%.4f', total * 0.0004)} " \
             "(at ~$0.0004 / image for gemini-2.5-flash-image)."
        rows.each do |row|
          slug = (row.concept&.slug.presence || row.concept&.name.to_s.parameterize(separator: "-")).to_s
          path = output_dir.join("#{slug}.webp")
          meta = row.payload["illustration_meta"] || {}
          status = if row.payload["illustration_url"].present? && File.exist?(path) && meta["style"] == style
                     "skip (up-to-date)"
          else
                     "generate"
          end
          puts "  - #{slug} → #{status}"
        end
        next
      end

      generated = 0
      skipped = 0
      failures = []

      rows.each_with_index do |row, idx|
        slug = (row.concept&.slug.presence || row.concept&.name.to_s.parameterize(separator: "-")).to_s
        puts "[#{idx + 1}/#{total}] #{slug}..."

        result = Academy::Illustrations::Generate.call(lens_cache: row, force: force)

        if result.success?
          if result.data[:skipped]
            skipped += 1
            puts "    skipped (up-to-date)"
          else
            generated += 1
            puts "    ok → #{result.data[:url]} (#{result.data[:bytes_written]} bytes)"
          end
        else
          failures << [ slug, result.error, result.data ]
          Rails.logger.warn("[academy:illustrations:generate] #{slug} failed: #{result.error} #{result.data.inspect}")
          puts "    FAILED: #{result.error} — #{result.data.inspect}"
        end
      end

      puts ""
      puts "Summary: generated=#{generated} skipped=#{skipped} failed=#{failures.size}"
      failures.each { |slug, err, data| puts "  ✗ #{slug}: #{err} #{data.inspect}" }
    end
  end
end
