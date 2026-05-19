# frozen_string_literal: true

module Academy
  module Lens
    # Closed enumeration of the 8 lens types in v5.
    #
    # Each entry pins:
    #   * `ui_primitive`     — the renderable interaction primitive (Phase 4).
    #   * `prompt_template`  — ERB template file under prompts/.
    #   * `schema_file`      — JSON Schema file under schemas/.
    #   * `template_version` — bumped when the prompt changes; invalidates cache
    #                          lazily (REQ-LGEN-010).
    #   * `closure_eligible` — true for lens types that close a mission journey
    #                          (analogy_bridge, ethical).
    #
    # Adding a new lens type means: code change here, new prompt + schema,
    # migration on `academy_lens_cache.lens_type` check constraint. No runtime
    # add. See REQ-LGEN-001.
    module Catalog
      module_function

      Entry = Data.define(
        :type, :ui_primitive, :prompt_template, :schema_file, :template_version,
        :closure_eligible, :temperature, :max_tokens
      ) do
        def closure? = closure_eligible
      end

      # Per-lens LLM tuning. Rationale:
      #   * scientific/statistical/historical → precision-oriented (low temp).
      #   * narrative/ethical/analogy_bridge → creativity (higher temp).
      #   * engineering/first_person → moderate.
      #
      # max_tokens here is an upper bound (Academy.config.max_tokens is the
      # global ceiling at 10000). Per-lens caps stay tighter than global so
      # a single lens generation can't burn the whole budget if the LLM
      # decides to over-explain — schemas + caps act as belt-and-suspenders.
      TYPES = {
        scientific:      Entry.new(
          type: :scientific, ui_primitive: :predict_reveal,
          prompt_template: "scientific.md.erb", schema_file: "scientific.json",
          template_version: "scientific.v5", closure_eligible: false,
          temperature: 0.4, max_tokens: 10_000
        ),
        narrative:       Entry.new(
          type: :narrative, ui_primitive: :card_stack,
          prompt_template: "narrative.md.erb", schema_file: "narrative.json",
          template_version: "narrative.v5", closure_eligible: false,
          temperature: 0.7, max_tokens: 10_000
        ),
        ethical:         Entry.new(
          type: :ethical, ui_primitive: :compare_cases,
          prompt_template: "ethical.md.erb", schema_file: "ethical.json",
          template_version: "ethical.v4", closure_eligible: true,
          temperature: 0.7, max_tokens: 10_000
        ),
        statistical:     Entry.new(
          type: :statistical, ui_primitive: :predict_slider,
          prompt_template: "statistical.md.erb", schema_file: "statistical.json",
          template_version: "statistical.v4", closure_eligible: false,
          temperature: 0.35, max_tokens: 10_000
        ),
        engineering:     Entry.new(
          type: :engineering, ui_primitive: :drag_list,
          prompt_template: "engineering.md.erb", schema_file: "engineering.json",
          template_version: "engineering.v4", closure_eligible: false,
          temperature: 0.55, max_tokens: 10_000
        ),
        historical:      Entry.new(
          type: :historical, ui_primitive: :timeline,
          prompt_template: "historical.md.erb", schema_file: "historical.json",
          template_version: "historical.v4", closure_eligible: false,
          temperature: 0.5, max_tokens: 10_000
        ),
        first_person:    Entry.new(
          type: :first_person, ui_primitive: :embodied_action,
          prompt_template: "first_person.md.erb", schema_file: "first_person.json",
          template_version: "first_person.v4", closure_eligible: false,
          temperature: 0.6, max_tokens: 10_000
        ),
        analogy_bridge:  Entry.new(
          type: :analogy_bridge, ui_primitive: :bridge_mapping,
          prompt_template: "analogy_bridge.md.erb", schema_file: "analogy_bridge.json",
          template_version: "analogy_bridge.v4", closure_eligible: true,
          temperature: 0.65, max_tokens: 10_000
        )
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

      def prompt_path(type)
        ROOT.join("prompts", fetch(type).prompt_template)
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
