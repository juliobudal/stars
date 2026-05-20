# frozen_string_literal: true

namespace :academy do
  desc "Audit Flesch-PT readability of all curated lens payloads"
  task audit_readability: :environment do
    counts = { ok: 0, warn: 0, block: 0 }
    rows   = []

    Academy::LensCache.curated.servable.includes(:concept).find_each do |cache|
      # Treat each leaf string as its own sentence — payload leaves often
      # lack terminators (mapping labels, choice labels), and joining with
      # a space collapses everything into a single huge "sentence", driving
      # FRE-PT deeply negative even for excellent content.
      text = collect_strings(cache.payload)
               .map { |s| s.strip.sub(/[.!?…]+\z/, "") }
               .reject(&:empty?)
               .join(". ")
      result = Academy::Llm::Readability.analyze(text)
      counts[result.tier] += 1
      rows << [ result.tier, result.score, cache.lens_type, cache.concept.slug ]
    end

    rows.sort_by { |t, s, *| [ t == :block ? 0 : (t == :warn ? 1 : 2), s ] }
        .each { |t, s, lens, slug| puts "[#{t.to_s.ljust(5)}] #{s.to_s.rjust(5)}  #{lens.to_s.ljust(15)}  #{slug}" }

    total = counts.values.sum
    puts ""
    puts "Total curated rows: #{total}"
    puts "  ok    (FRE >= 60): #{counts[:ok]}   #{pct(counts[:ok], total)}%"
    puts "  warn  (FRE 50-60): #{counts[:warn]}   #{pct(counts[:warn], total)}%"
    puts "  block (FRE < 50):  #{counts[:block]}   #{pct(counts[:block], total)}%"
  end

  def collect_strings(node, acc = [])
    case node
    when Hash  then node.each_value { |v| collect_strings(v, acc) }
    when Array then node.each { |v| collect_strings(v, acc) }
    when String then acc << node
    end
    acc
  end

  def pct(n, total)
    return "0" if total.zero?
    ((n.to_f / total) * 100).round(1)
  end
end
