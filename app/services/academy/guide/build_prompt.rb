# frozen_string_literal: true

module Academy
  module Guide
    # Assembles the system prompt for a Guide chat turn.
    #
    # Output:
    #   ok({ system:, mission_context:, lens_summaries: })
    #
    # Where `system` is the final string sent as the OpenAI `system` message.
    #
    # Token budget: the assembled string is capped at MAX_SYSTEM_TOKENS using
    # the cheap chars/4 estimator. When over, lens summaries are dropped
    # newest-first until we fit. Persona, concept essence, and central
    # insight are NEVER truncated — if even the floor doesn't fit we still
    # return them.
    class BuildPrompt < ApplicationService
      MAX_SYSTEM_TOKENS = 1500
      CHARS_PER_TOKEN   = 4

      def initialize(learner:, mission:)
        @learner = learner
        @mission = mission
      end

      def call
        concept = @mission.concept
        floor = base_floor(concept: concept, mission: @mission)
        lens_summaries = collect_lens_summaries(concept: concept, learner: @learner, mission: @mission)

        system_text = compose(floor: floor, lens_summaries: lens_summaries)

        ok(
          system: system_text,
          mission_context: { concept_name: concept.name, central_insight: @mission.central_insight },
          lens_summaries: lens_summaries
        )
      end

      private

      def base_floor(concept:, mission:)
        <<~TXT
          #{Persona::VOICE}

          # CONCEITO DESTA MISSÃO

          Nome: #{concept.name}
          Slug: #{concept.slug}
          Essência (frase-norte do currículo): #{concept.the_essence.presence || '—'}

          # SACADA CENTRAL DA MISSÃO

          #{mission.central_insight.presence || mission.learning_objective.to_s.strip}

          # MISSÃO

          Título: #{mission.title}
          Ângulo: #{mission.angle.presence || '—'}
        TXT
      end

      # Returns an array of lines like:
      #   "🔬 scientific — Cada beep custa ~23min de reconstrução de contexto · fonte: Gloria Mark, UC Irvine"
      #
      # Pulled from LensCache.curated for this mission's concept. Newest
      # (most-recent generated_at) last so truncation drops newest first.
      def collect_lens_summaries(concept:, learner:, mission:)
        visited_types = visited_lens_types(learner: learner, mission: mission)

        cache_rows = ::Academy::LensCache
                       .where(concept_id: concept.id, lens_type: visited_types)
                       .order(:generated_at)

        cache_rows.map { |row| summarize_lens(row) }.compact
      end

      def visited_lens_types(learner:, mission:)
        ::Academy::LearnerLensVisit
          .joins(:mission_progress)
          .where(
            academy_mission_progresses: { learner_id: learner.id, mission_id: mission.id },
            outcome: "completed"
          )
          .distinct
          .pluck(:lens_type)
      end

      def summarize_lens(row)
        emoji = lens_emoji(row.lens_type)
        claim, source = extract_claim_and_source(row.payload)
        return nil if claim.blank?
        line = "#{emoji} #{row.lens_type} — #{claim}"
        line += " · fonte: #{source}" if source.present?
        line
      end

      LENS_EMOJI = {
        "narrative" => "📖", "first_person" => "👁", "scientific" => "🔬",
        "statistical" => "📈", "engineering" => "🛠", "ethical" => "⚖️",
        "historical" => "🕰", "analogy_bridge" => "🔭"
      }.freeze

      def lens_emoji(type)
        LENS_EMOJI[type.to_s] || "•"
      end

      # Each lens schema names the "headline" differently. We probe known
      # field names and fall back to nothing rather than dumping JSON.
      def extract_claim_and_source(payload)
        return [ nil, nil ] unless payload.is_a?(Hash)

        claim = first_present(payload,
          "central_claim", "claim", "headline", "reveal_text",
          "scene_3_text", "answer_text", "consequence_text"
        )
        source = first_present(payload, "source", "fonte", "citation")
        [ trim(claim), trim(source) ]
      end

      def first_present(hash, *keys)
        keys.each do |k|
          val = hash[k] || hash[k.to_sym]
          return val if val.is_a?(String) && val.strip.length.positive?
        end
        nil
      end

      def trim(str, max: 220)
        return nil if str.nil?
        s = str.to_s.strip.tr("\n", " ").squeeze(" ")
        s.length > max ? "#{s[0, max - 1]}…" : s
      end

      def compose(floor:, lens_summaries:)
        summaries = lens_summaries.dup
        loop do
          candidate = build_text(floor: floor, lens_summaries: summaries)
          return candidate if estimate_tokens(candidate) <= MAX_SYSTEM_TOKENS
          break if summaries.empty?
          summaries.pop # drop newest-first
        end
        # Floor alone (over budget but everything truncatable was dropped):
        build_text(floor: floor, lens_summaries: [])
      end

      def build_text(floor:, lens_summaries:)
        return floor if lens_summaries.empty?
        <<~TXT
          #{floor}

          # LIÇÕES QUE A CRIANÇA ACABOU DE VER

          #{lens_summaries.join("\n")}
        TXT
      end

      def estimate_tokens(str) = (str.length / CHARS_PER_TOKEN.to_f).ceil
    end
  end
end
