# frozen_string_literal: true

module Academy
  # Curated pool of one-line wisdom quotes shown inside the Academy
  # loading overlay during page/lens transitions. With curated-static
  # content the wait is short, but the overlay still masks the transition
  # and gives the kid a beat to read one line.
  #
  # Editorial mix: Bíblia (Provérbios/Eclesiastes/Tiago, acessível para
  # crianças) + filósofos clássicos + cientistas + educadores brasileiros
  # + escritores/poetas + pensadores cristãos + outras culturas + alguns
  # ensinamentos originais d'O Guia. Fonte sempre explícita.
  # Curadoria em `config/academy_wisdom_pills.yml`.
  #
  # Usage:
  #   pill = Academy::WisdomPills.sample
  #   pill.text   # => "O começo da sabedoria é querer aprender."
  #   pill.source # => "Provérbios 4:7"
  #   pill.theme  # => "sabedoria" (or nil)
  #
  #   # Optional theme-aware sampling (falls back to uniform if the
  #   # filtered pool has fewer than 5 pills):
  #   Academy::WisdomPills.sample(theme: :curiosidade)
  module WisdomPills
    Pill = Data.define(:text, :source, :theme)

    CONFIG_PATH = Rails.root.join("config/academy_wisdom_pills.yml")
    private_constant :CONFIG_PATH

    # Minimum number of pills required for a themed sample to be honored.
    # Below this threshold we fall back to a uniform sample over `all`
    # to avoid the kid seeing the same 1-2 themed pills repeatedly.
    THEME_MIN_POOL = 5
    private_constant :THEME_MIN_POOL

    class << self
      def all
        @all ||= load_from_disk
      end

      # `theme:` is optional. Accepts a Symbol or String matching one of
      # the curated themes (curiosidade | escuta | perseveranca | humor |
      # coragem | sabedoria). Unknown / nil theme → uniform sample.
      def sample(theme: nil)
        return Pill.new(text: "O Guia está pensando…", source: "O Guia", theme: nil) if all.empty?

        if theme
          theme_str = theme.to_s
          filtered = all.select { |p| p.theme == theme_str }
          return filtered.sample if filtered.size >= THEME_MIN_POOL
        end

        all.sample
      end

      # Re-read the YAML file (test helper / dev reload).
      def reload!
        @all = nil
        all
      end

      private

      def load_from_disk
        return [] unless CONFIG_PATH.exist?
        raw = YAML.safe_load_file(CONFIG_PATH) || {}
        Array(raw["pills"]).filter_map do |entry|
          text = entry["text"].to_s.strip
          source = entry["source"].to_s.strip
          next if text.empty? || source.empty?
          theme = entry["theme"]&.to_s&.strip
          theme = nil if theme.nil? || theme.empty?
          Pill.new(text:, source:, theme:)
        end
      end
    end
  end
end
