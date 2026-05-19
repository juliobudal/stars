# frozen_string_literal: true

module Academy
  # Curated pool of one-line wisdom quotes shown inside the Academy loading
  # overlay while the LLM generates the next lens (5–30s on cold start).
  #
  # Editorial mix: Provérbios/Eclesiastes/Tiago (acessível para crianças)
  # + filósofos e educadores universais + ensinamentos originais d'O Guia.
  # Fonte sempre explícita. Curadoria em `config/academy_wisdom_pills.yml`.
  #
  # Usage:
  #   pill = Academy::WisdomPills.sample
  #   pill.text   # => "O começo da sabedoria é querer aprender."
  #   pill.source # => "Provérbios 4:7"
  module WisdomPills
    Pill = Data.define(:text, :source)

    CONFIG_PATH = Rails.root.join("config/academy_wisdom_pills.yml")
    private_constant :CONFIG_PATH

    class << self
      def all
        @all ||= load_from_disk
      end

      def sample
        return Pill.new(text: "O Guia está pensando…", source: "O Guia") if all.empty?
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
          Pill.new(text:, source:)
        end
      end
    end
  end
end
