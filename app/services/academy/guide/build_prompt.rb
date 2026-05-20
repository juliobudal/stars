# frozen_string_literal: true

module Academy
  module Guide
    # Assembles the system prompt for one Guide chat turn.
    #
    # Output:
    #   ok({ system:, mission_context:, lens_summaries: })
    #
    # The `system` string is the final message sent to the LLM as the
    # `system` role. It ships four blocks under Persona::VOICE:
    #   1. CONCEITO + SACADA — frase-essência + insight central da missão
    #   2. LENTES RECENTES — scene anchors das aulas que a criança ACABOU
    #      de ver (personagens, números, cenas — não só headlines)
    #   3. ESTADO DO APRENDIZ — mastery tier, wrong-streak, conceitos
    #      vizinhos já dominados (para fazer ponte)
    #   4. MOMENTO — dia/hora locais (timezone do learner)
    #
    # Token budget: capped at MAX_SYSTEM_TOKENS via the cheap chars/4
    # estimator. Lens-scene lines drop newest-first when over budget.
    # Voice + concept floor + sacada + estado + momento are NEVER
    # truncated — they're the contract that keeps the Guide on-topic.
    class BuildPrompt < ApplicationService
      MAX_SYSTEM_TOKENS = 1800
      CHARS_PER_TOKEN   = 4

      def initialize(learner:, mission:)
        @learner = learner
        @mission = mission
      end

      def call
        concept = @mission.concept
        floor   = base_floor(concept: concept, mission: @mission)
        lens_scenes = collect_lens_scenes(concept: concept, learner: @learner, mission: @mission)
        state_block  = learner_state_block(concept: concept, learner: @learner)
        moment_block = moment_block(learner: @learner)

        system_text = compose(
          floor: floor,
          lens_scenes: lens_scenes,
          state_block: state_block,
          moment_block: moment_block
        )

        ok(
          system: system_text,
          mission_context: { concept_name: concept.name, central_insight: @mission.central_insight },
          lens_summaries: lens_scenes
        )
      end

      private

      # ── floor ────────────────────────────────────────────────────────

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

      # ── lens recent scenes ───────────────────────────────────────────
      #
      # Each line carries a CONCRETE anchor (character name, number,
      # cena-chave) so the LLM can reference what the kid actually saw
      # — not just a generic claim. Ordered oldest → newest so the
      # truncation loop drops the freshest first (keeping older context
      # the kid already moved past would be the wrong tradeoff; we keep
      # the OLDEST anchors which the kid had time to internalize).

      LENS_EMOJI = {
        "narrative" => "📖", "first_person" => "👁", "scientific" => "🔬",
        "statistical" => "📈", "engineering" => "🛠", "ethical" => "⚖️",
        "historical" => "🕰", "analogy_bridge" => "🔭"
      }.freeze

      def collect_lens_scenes(concept:, learner:, mission:)
        visited = visited_lens_caches(learner: learner, mission: mission, concept: concept)
        visited.map { |lt, cache| line_for(lens_type: lt, cache: cache) }.compact
      end

      def visited_lens_caches(learner:, mission:, concept:)
        rows = ::Academy::LearnerLensVisit
                 .joins(:mission_progress)
                 .where(
                   learner_id: learner.id,
                   concept_id: concept.id,
                   outcome: "completed",
                   academy_mission_progresses: { mission_id: mission.id }
                 )
                 .where.not(lens_cache_id: nil)
                 .includes(:lens_cache)
                 .order(:opened_at)

        # Dedupe by lens_type — if the kid replayed the same type, keep oldest.
        seen = {}
        rows.each { |r| seen[r.lens_type] ||= r.lens_cache }
        seen
      end

      def line_for(lens_type:, cache:)
        return nil if cache.nil? || cache.payload.blank?
        emoji = LENS_EMOJI[lens_type] || "•"
        anchor = scene_anchor(lens_type: lens_type, payload: cache.payload)
        return nil if anchor.blank?
        "#{emoji} #{lens_type} — #{anchor}"
      end

      # Per-lens-type scene anchor extractor. Each returns a single string
      # ≤ ~220 chars that gives the LLM something concrete to point at.
      def scene_anchor(lens_type:, payload:)
        case lens_type
        when "narrative"      then anchor_narrative(payload)
        when "scientific"     then anchor_scientific(payload)
        when "statistical"    then anchor_statistical(payload)
        when "analogy_bridge" then anchor_analogy(payload)
        when "first_person"   then anchor_first_person(payload)
        when "ethical"        then anchor_ethical(payload)
        when "engineering"    then anchor_engineering(payload)
        when "historical"     then anchor_historical(payload)
        else
          # Unknown lens type / legacy payload: fall back to claim+source.
          fallback_anchor(payload)
        end
      end

      def anchor_narrative(p)
        char = p["character"] || {}
        name = char["name"]
        age  = char["age"]
        scene = (p["scenes"].is_a?(Array) ? p["scenes"].first&.dig("text") : nil)
        return fallback_anchor(p) if name.blank?
        head = "Personagem: #{name}, #{age || '?'}"
        scene_tail = scene.present? ? " · cena: #{trim(scene, max: 140)}" : ""
        "#{head}#{scene_tail}"
      end

      def anchor_scientific(p)
        head    = p["headline"].to_s.strip
        first_step = (p["mechanism_steps"].is_a?(Array) ? p["mechanism_steps"].first : nil).to_s.strip
        return fallback_anchor(p) if head.empty? && first_step.empty?
        parts = []
        parts << "Manchete: #{trim(head, max: 140)}" if head.present?
        parts << "passo-chave: #{trim(first_step, max: 140)}" if first_step.present?
        parts.join(" · ")
      end

      def anchor_statistical(p)
        ask    = p["predict_prompt"].to_s.strip
        value  = p["reveal_value"]
        unit   = p["predict_unit"]
        return fallback_anchor(p) if ask.empty? && value.nil?
        parts = []
        parts << "Pergunta: #{trim(ask, max: 160)}" if ask.present?
        parts << "revelado: #{value}#{unit ? " #{unit}" : ''}" if value
        parts.join(" · ")
      end

      def anchor_analogy(p)
        src = p.dig("source_domain", "name")
        tgt = p.dig("target_domain", "name")
        return fallback_anchor(p) if src.blank? || tgt.blank?
        "Ponte: #{trim(src, max: 80)} ↔ #{trim(tgt, max: 80)}"
      end

      def anchor_first_person(p)
        ask = p["action_prompt"].to_s.strip
        return fallback_anchor(p) if ask.empty?
        "Ação: #{trim(ask, max: 180)}"
      end

      def anchor_ethical(p)
        dilemma = p["dilemma"].to_s.strip
        a_title = p.dig("case_a", "title")
        b_title = p.dig("case_b", "title")
        return fallback_anchor(p) if dilemma.empty?
        contrast = (a_title && b_title) ? " · #{trim(a_title, max: 50)} vs #{trim(b_title, max: 50)}" : ""
        "Dilema: #{trim(dilemma, max: 140)}#{contrast}"
      end

      def anchor_engineering(p)
        challenge = p["challenge"].to_s.strip
        return fallback_anchor(p) if challenge.empty?
        "Desafio: #{trim(challenge, max: 180)}"
      end

      def anchor_historical(p)
        label  = p["pattern_label"].to_s.strip
        years  = (p["scenes"].is_a?(Array) ? p["scenes"].map { |s| s["year"] }.compact : []).first(3)
        return fallback_anchor(p) if label.empty?
        yrs = years.any? ? " (#{years.join(' → ')})" : ""
        "Padrão: #{trim(label, max: 140)}#{yrs}"
      end

      # Used when a payload doesn't match its lens schema (legacy /
      # hand-authored test payloads using `central_claim`/`claim`).
      def fallback_anchor(p)
        claim = first_present(p, "central_claim", "claim", "headline", "reveal_text", "scene_3_text", "answer_text")
        source = first_present(p, "source", "fonte", "citation")
        return nil if claim.blank?
        line = trim(claim, max: 200)
        line += " · fonte: #{trim(source, max: 80)}" if source.present?
        line
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

      # ── learner state ────────────────────────────────────────────────

      def learner_state_block(concept:, learner:)
        return nil if learner.id.nil?

        ctx = ::Academy::Lens::LearnerContext.build(learner_id: learner.id, concept: concept)
        tier_line = if ctx.advanced?
                      "Aprendiz: avançado neste conceito (nível #{ctx.level}) — pode trazer nuance, edge case, aplicação não-óbvia."
        else
                      "Aprendiz: novato neste conceito (nível #{ctx.level}) — ancore em exemplos simples do dia-a-dia."
        end

        adaptive = ctx.wrong_streak >= 2 ? "Sinal: errou as últimas #{ctx.wrong_streak} micro-checks. Recapture com paciência, sem julgar." : nil
        bridged = bridged_concepts(concept: concept, learner: learner)
        bridge_line = bridged.any? ? "Pontes possíveis (conceitos vizinhos JÁ vistos): #{bridged.join(', ')}." : nil

        lines = [ tier_line, adaptive, bridge_line ].compact
        return nil if lines.empty?
        lines.join("\n")
      end

      # Concepts the learner has at least seen one lens of, AND that are
      # adjacent to this mission's concept via concept_edges. Bridging
      # invites the Guide to draw lines kid has earned.
      def bridged_concepts(concept:, learner:)
        adjacent_ids = (concept.outgoing_edges.pluck(:to_concept_id) +
                        concept.incoming_edges.pluck(:from_concept_id)).uniq
        return [] if adjacent_ids.empty?

        names = ::Academy::Concept
                  .where(id: adjacent_ids)
                  .where(id: ::Academy::LearnerLensVisit
                               .for_learner(learner.id)
                               .completed
                               .select(:concept_id))
                  .pluck(:name)
        names.first(4)
      end

      # ── moment ───────────────────────────────────────────────────────

      def moment_block(learner:)
        tz = learner.respond_to?(:timezone) ? learner.timezone.presence : nil
        tz ||= "UTC"
        local = Time.current.in_time_zone(tz)
        weekday = I18n.t("date.day_names", default: nil)&.[](local.wday) || local.strftime("%A")
        period =
          case local.hour
          when 5..11  then "manhã"
          when 12..17 then "tarde"
          when 18..21 then "noite"
          else "madrugada"
          end
        "#{weekday}, #{local.strftime('%H:%M')} (#{period}, fuso #{tz})"
      end

      # ── compose ──────────────────────────────────────────────────────

      def compose(floor:, lens_scenes:, state_block:, moment_block:)
        scenes = lens_scenes.dup
        loop do
          candidate = build_text(floor: floor, lens_scenes: scenes,
                                 state_block: state_block, moment_block: moment_block)
          return candidate if estimate_tokens(candidate) <= MAX_SYSTEM_TOKENS
          break if scenes.empty?
          scenes.pop # drop newest-first
        end
        build_text(floor: floor, lens_scenes: [], state_block: state_block, moment_block: moment_block)
      end

      def build_text(floor:, lens_scenes:, state_block:, moment_block:)
        sections = [ floor ]

        if lens_scenes.any?
          sections << <<~TXT.strip
            # LENTES RECENTES (cenas concretas que a criança VIU)

            #{lens_scenes.join("\n")}
          TXT
        end

        if state_block.present?
          sections << <<~TXT.strip
            # ESTADO DO APRENDIZ

            #{state_block}
          TXT
        end

        if moment_block.present?
          sections << <<~TXT.strip
            # MOMENTO

            #{moment_block}
          TXT
        end

        sections.join("\n\n") + "\n"
      end

      def estimate_tokens(str) = (str.length / CHARS_PER_TOKEN.to_f).ceil
    end
  end
end
