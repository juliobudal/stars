# frozen_string_literal: true

module Academy
  module Digests
    # Composes the weekly "Notícias da expedição" digest for one (parent, learner)
    # pair. Aggregates the last 7 days of activity and asks the LLM to summarize
    # in 4 narrative blocks (no metrics). Idempotent per (learner, week_starting).
    class Compose < ApplicationService
      def initialize(learner_id:, parent_id:, week_starting: Date.current.beginning_of_week(:monday), llm: Llm::Client.new)
        @learner_id    = learner_id
        @parent_id     = parent_id
        @week_starting = week_starting
        @llm           = llm
      end

      def call
        existing = ::Academy::ParentDigest.find_by(learner_id: @learner_id, week_starting: @week_starting)
        return ok(existing) if existing

        aggregates = collect_aggregates
        return ok(nil) if aggregates_empty?(aggregates)

        payload = build_payload(aggregates)

        digest = ::Academy::ParentDigest.create!(
          learner_id: @learner_id,
          parent_id: @parent_id,
          week_starting: @week_starting,
          payload: payload,
          composed_at: Time.current
        )
        ok(digest)
      end

      private

      def collect_aggregates
        from = @week_starting.to_time
        to   = @week_starting.next_week.to_time

        {
          patterns_evolved: ::Academy::LearnerConcept
                              .for_learner(@learner_id)
                              .where("(evolved_to_2_at BETWEEN :a AND :b) OR (evolved_to_3_at BETWEEN :a AND :b)", a: from, b: to)
                              .includes(:concept)
                              .map { |lc| [ lc.concept.name, lc.level ] },
          transfers: ::Academy::TransferDetection
                       .for_learner(@learner_id)
                       .where(detected_at: from...to)
                       .includes(:from_concept, :to_concept)
                       .map { |t| [ t.from_concept.name, t.to_concept.name ] },
          missions_completed: ::Academy::MissionProgress
                                .where(learner_id: @learner_id, status: %i[completed mastered])
                                .where(completed_at: from...to)
                                .includes(mission: :subject)
                                .map { |p| p.mission.title },
          wagers_reported: ::Academy::PracticeWager
                             .for_learner(@learner_id)
                             .where(reported_at: from...to)
                             .includes(:mission)
                             .map { |w| { mission: w.mission.title, bet: w.guide_bet_count, actual: w.learner_actual_count } },
          virtue_sightings: ::Academy::VirtueSighting
                              .for_learner(@learner_id)
                              .where(spotted_at: from...to)
                              .pluck(:virtue_slug, :context),
          lens_journeys: lens_journey_aggregate(from, to)
        }
      end

      # v5: per-concept summary of which lens types were visited this week.
      # Produces an array like
      #   [{ concept: "Dopamina", lens_types: [:narrative, :scientific, :analogy_bridge], visits: 3 }, ...]
      def lens_journey_aggregate(from, to)
        visits = ::Academy::LearnerLensVisit
                   .for_learner(@learner_id)
                   .where(opened_at: from...to)
                   .includes(:concept)

        visits.group_by(&:concept_id).map do |_concept_id, rows|
          concept = rows.first.concept
          {
            concept: concept&.name,
            lens_types: rows.map(&:lens_type).uniq,
            visits: rows.size
          }
        end
      end

      def aggregates_empty?(agg)
        agg.values.all?(&:empty?)
      end

      def build_payload(agg)
        return fallback_payload(agg) unless ::Academy.configured?

        prompt_user = <<~U
          Atividade desta semana (resumida, sem números técnicos):
          - Ângulos atravessados por conceito: #{format_lens_journeys(agg[:lens_journeys])}
          - Padrões que evoluíram no Atlas: #{agg[:patterns_evolved].map { |n, l| "#{n} (nv #{l})" }.join('; ').presence || '(nenhum)'}
          - Transferências cross-area: #{agg[:transfers].map { |a, b| "#{a} -> #{b}" }.join('; ').presence || '(nenhuma)'}
          - Missões concluídas: #{agg[:missions_completed].join('; ').presence || '(nenhuma)'}
          - Apostas reportadas: #{agg[:wagers_reported].map { |w| "#{w[:mission]} (apostei #{w[:bet]}, ela reportou #{w[:actual]})" }.join('; ').presence || '(nenhuma)'}
          - Avistamentos de virtude: #{agg[:virtue_sightings].map { |s, c| "#{s}: #{c}" }.join('; ').presence || '(nenhum)'}

          Escreva 4 blocos curtos para um digest pai-filho semanal.
          Tom: jornal de bordo de expedição (Cousteau/naturalista), não terapeuta nem professor.
          PROIBIDO: psicologismo ("como ela se sente", "processo emocional"),
          tom contemplativo ("que semana reflexiva..."), métricas brutas
          ("completou X missões, evoluiu Y conceitos"), linguagem de relatório
          escolar ("desempenho", "progresso"), perguntas terapêuticas dirigidas ao pai.
          JSON estrito com as chaves:
          {
            "patterns_discovered": "1 parágrafo curto sobre o que ele descobriu",
            "biggest_reveal": "1 frase sobre o achado mais surpreendente da semana",
            "conversation_starter": "1 pergunta natural pra mesa de jantar — sem revelar a sopa",
            "kid_sent_you": "frase curta sobre o que o kid mandou explicitamente (se houver) ou string vazia"
          }
        U

        response = @llm.chat(
          messages: [ { role: "user", content: prompt_user } ],
          response_format: { type: "json_object" },
          temperature: 0.5,
          max_tokens: 600
        )
        parsed = JSON.parse(response[:content].to_s)
        parsed.slice(*::Academy::ParentDigest::PAYLOAD_BLOCKS)
      rescue Llm::Client::Error, JSON::ParserError
        fallback_payload(agg)
      end

      def fallback_payload(agg)
        {
          "patterns_discovered" => agg[:patterns_evolved].map { |n, _| n }.join(", ").presence || "Nada de novo no Atlas esta semana.",
          "biggest_reveal" => agg[:missions_completed].first.to_s,
          "conversation_starter" => "Pergunte: qual foi o padrão mais doido que você descobriu essa semana?",
          "kid_sent_you" => ""
        }
      end

      def format_lens_journeys(journeys)
        return "(nenhum)" if journeys.blank?

        journeys.map do |j|
          types = j[:lens_types].map { |t| ::Academy::Lens::Catalog.parent_label(t) }.join(", ")
          "#{j[:concept]} (#{j[:visits]} ângulos: #{types})"
        end.join("; ")
      end
    end
  end
end
