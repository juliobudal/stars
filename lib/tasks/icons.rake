namespace :icons do
  desc "Build public/hugeicons-manifest.json from lib/icons/hugeicons_seed.json"
  task :sync do
    seed_path = Rails.root.join("lib/icons/hugeicons_seed.json")
    out_path  = Rails.root.join("public/hugeicons-manifest.json")

    raise "Seed missing at #{seed_path}. Re-run mcp__hugeicons__list_icons in a Claude Code session and persist the result." unless seed_path.exist?

    seed = JSON.parse(seed_path.read)

    manifest = seed.map do |entry|
      slug = entry["slug"] || entry["name"].to_s.parameterize
      name = entry["name"].to_s.tr("-_", "  ").strip
      tags = Array(entry["tags"]).map(&:to_s)
      tags = slug.split("-").reject(&:empty?) if tags.empty?
      { slug: slug, name: name, tags: tags }
    end

    out_path.write(JSON.pretty_generate(manifest))
    puts "Wrote #{manifest.size} icons to #{out_path.relative_path_from(Rails.root)}"
  end
end
