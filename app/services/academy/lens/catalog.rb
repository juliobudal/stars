# frozen_string_literal: true

module Academy
  module Lens
    # Closed enumeration of the 8 lens types in v5.
    #
    # Each entry pins:
    #   * `ui_primitive`     — the renderable interaction primitive.
    #   * `schema_file`      — JSON Schema file under schemas/.
    #   * `closure_eligible` — true for lens types that close a mission
    #                          journey (analogy_bridge, ethical).
    #
    # Adding a new lens type means: code change here, new schema, new
    # curated payloads under db/seeds/academy_lens_payloads/<type>/, and
    # likely an updated `academy_lens_cache.lens_type` check constraint.
    module Catalog
      module_function

      Entry = Data.define(
        :type, :ui_primitive, :schema_file, :closure_eligible
      ) do
        def closure? = closure_eligible
      end

      TYPES = {
        scientific:     Entry.new(type: :scientific,     ui_primitive: :predict_reveal,   schema_file: "scientific.json",     closure_eligible: false),
        narrative:      Entry.new(type: :narrative,      ui_primitive: :card_stack,       schema_file: "narrative.json",      closure_eligible: false),
        ethical:        Entry.new(type: :ethical,        ui_primitive: :compare_cases,    schema_file: "ethical.json",        closure_eligible: true),
        statistical:    Entry.new(type: :statistical,    ui_primitive: :predict_slider,   schema_file: "statistical.json",    closure_eligible: false),
        engineering:    Entry.new(type: :engineering,    ui_primitive: :drag_list,        schema_file: "engineering.json",    closure_eligible: false),
        historical:     Entry.new(type: :historical,     ui_primitive: :timeline,         schema_file: "historical.json",     closure_eligible: false),
        first_person:   Entry.new(type: :first_person,   ui_primitive: :embodied_action,  schema_file: "first_person.json",   closure_eligible: false),
        analogy_bridge: Entry.new(type: :analogy_bridge, ui_primitive: :bridge_mapping,   schema_file: "analogy_bridge.json", closure_eligible: true)
      }.freeze

      ROOT = Rails.root.join("app/services/academy/lens").freeze

      # User-facing labels. "Lente" is an internal architectural term — the
      # kid never sees it. The kid sees the ACTION they're about to do.
      # Parents see slightly more descriptive labels in digests/journeys.
      KID_ACTION_LABELS = {
        scientific:     { emoji: "🔬", action: "Como funciona" },
        narrative:      { emoji: "📖", action: "Conta a história" },
        ethical:        { emoji: "⚖️", action: "Você decide" },
        statistical:    { emoji: "📈", action: "Adivinha" },
        engineering:    { emoji: "🛠", action: "Você que constrói" },
        historical:     { emoji: "🕰", action: "Atravessando o tempo" },
        first_person:   { emoji: "👁", action: "Faz isso agora" },
        analogy_bridge: { emoji: "🔭", action: "Em outro lugar" }
      }.freeze

      PARENT_LABELS = {
        scientific:     "Mecanismo",
        narrative:      "História",
        ethical:        "Dilema",
        statistical:    "Predição",
        engineering:    "Projeto",
        historical:     "Padrão no tempo",
        first_person:   "Experimento de corpo",
        analogy_bridge: "Transferência"
      }.freeze

      def types
        TYPES.keys
      end

      def closure_types
        TYPES.each_pair.select { |_, e| e.closure? }.map { |k, _| k }
      end

      def fetch(type)
        sym = type.to_sym
        TYPES.fetch(sym) { raise ArgumentError, "Unknown lens type: #{type.inspect}" }
      end

      def schema_path(type)
        ROOT.join("schemas", fetch(type).schema_file)
      end

      def kid_action_label(type)
        KID_ACTION_LABELS.fetch(type.to_sym, { emoji: "✨", action: "Continua" })
      end

      def parent_label(type)
        PARENT_LABELS.fetch(type.to_sym, type.to_s.humanize)
      end
    end
  end
end
