namespace :icons do
  desc "Build public/hugeicons-manifest.json from lib/icons/hugeicons_seed.json"
  task :sync do
    seed_path = Rails.root.join("lib/icons/hugeicons_seed.json")
    out_path  = Rails.root.join("public/hugeicons-manifest.json")

    raise "Seed missing at #{seed_path}. Re-run mcp__hugeicons__list_icons in a Claude Code session and persist the result." unless seed_path.exist?

    seed = JSON.parse(seed_path.read)

    css_path = Rails.root.join("app/assets/stylesheets/vendors/hugeicons.css")
    raise "hugeicons.css missing at #{css_path}" unless css_path.exist?
    available = css_path.read.scan(/\.hgi-stroke\.hgi-([a-z0-9-]+)::before/).flatten.to_set

    manifest = seed.filter_map do |entry|
      slug = entry["slug"] || entry["name"].to_s.parameterize
      next unless available.include?(slug)
      name = entry["name"].to_s.tr("-_", "  ").strip
      tags =
        case entry["tags"]
        when String then entry["tags"].split(/\s*,\s*/).reject(&:empty?)
        else Array(entry["tags"]).map(&:to_s)
        end
      tags = slug.split("-").reject(&:empty?) if tags.empty?
      { slug: slug, name: name, tags: tags }
    end

    skipped = seed.size - manifest.size
    out_path.write(JSON.generate(manifest))
    puts "Wrote #{manifest.size} icons to #{out_path.relative_path_from(Rails.root)} (skipped #{skipped} without stroke glyph)"
  end
end

if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance([ "icons:sync" ])
end
