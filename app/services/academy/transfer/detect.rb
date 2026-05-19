# frozen_string_literal: true

module Academy
  module Transfer
    # LLM-judged detector of spontaneous cross-area concept use.
    #
    # Runs over a single `Academy::Message` (learner role, content > 40 chars,
    # non-checkpoint). Asks the judge whether the kid applied any concept
    # already in their Pokédex but NOT part of the current mission's concept
    # set. Each high-confidence (≥0.75) hit becomes a TransferDetection +
    # promotes the from_concept to Pokédex `mastered`.
    #
    # The service is callable synchronously but is normally invoked via
    # Academy::Transfer::DetectJob.
    class Detect < ApplicationService
      MIN_CONTENT_LENGTH = 40
      LOOKBACK = 20

      def initialize(message:, judge: Llm::Client.new, config: ::Academy.config)
        @message = message
        @judge   = judge
        @config  = config
      end

      def call
        return ok(skipped: :short)        if @message.content.to_s.strip.length < MIN_CONTENT_LENGTH
        return ok(skipped: :not_learner)  unless learner_message?
        return ok(skipped: :checkpoint)   if checkpoint_answer?

        progress  = @message.session.mission_progress
        return ok(skipped: :no_progress) unless progress

        learner_id = progress.learner_id
        mission    = progress.mission
        current_concept_ids = Array(mission.concept_id).compact
        current_slugs       = Array(mission.concept&.slug).compact

        known = candidate_concepts(learner_id, current_concept_ids)
        return ok(skipped: :no_candidates) if known.empty?

        applied = invoke_judge(known: known, current_slugs: current_slugs)
        return ok(skipped: :judge_returned_none) if applied.empty?

        detections = persist_detections!(applied, learner_id, current_concept_ids, mission)
        ok(detections)
      rescue Llm::Client::Error, JSON::ParserError => e
        fail_with("Transfer judge unavailable: #{e.class.name.demodulize}",
                  data: { exception: e.message })
      end

      private

      def learner_message?
        @message.role == "learner" || @message.role == ::Academy::Message.roles[:learner].to_s
      end

      def checkpoint_answer?
        @message.metadata.is_a?(Hash) && @message.metadata["kind"] == "answer"
      end

      def candidate_concepts(learner_id, exclude_concept_ids)
        ::Academy::LearnerConcept
          .for_learner(learner_id)
          .where.not(concept_id: exclude_concept_ids)
          .where("level >= ?", 1)
          .order(last_seen_at: :desc)
          .limit(LOOKBACK)
          .includes(:concept)
          .map(&:concept)
      end

      def invoke_judge(known:, current_slugs:)
        messages = [
          { role: "system", content: Llm::TransferPersona::VOICE },
          { role: "user",   content: Llm::TransferPersona.user_prompt(
            content: @message.content, known_concepts: known,
            current_concept_slugs: current_slugs
          ) }
        ]

        # gpt-5-nano is a reasoning model: max_tokens must cover both the
        # internal reasoning trace and the JSON response. 400 starves it.
        # 1200 + effort: "minimal" keeps the call cheap (~$0.0005/call) and
        # finishes in under a second.
        result = @judge.chat(
          messages: messages,
          response_format: { type: "json_object" },
          model: @config.judge_model,
          temperature: 0.1,
          max_tokens: 1200,
          reasoning: { effort: @config.judge_reasoning_effort }
        )

        parsed = JSON.parse(result[:content].to_s)
        Array(parsed["applied"]).filter_map do |entry|
          slug = entry["slug"].to_s
          conf = entry["confidence"].to_f
          next unless slug.present? && conf >= ::Academy::TransferDetection::MIN_CONFIDENCE

          { slug: slug, confidence: conf, snippet: entry["snippet"].to_s }
        end
      end

      def persist_detections!(applied, learner_id, current_concept_ids, mission)
        to_concept = ::Academy::Concept.find_by(id: current_concept_ids.first)
        return [] unless to_concept

        applied.filter_map do |entry|
          from = ::Academy::Concept.find_by(slug: entry[:slug])
          next if from.nil? || from.id == to_concept.id

          detection = ::Academy::TransferDetection.create!(
            learner_id: learner_id,
            from_concept: from,
            to_concept: to_concept,
            message: @message,
            confidence: entry[:confidence],
            evidence_excerpt: entry[:snippet].first(280),
            detected_at: Time.current
          )

          ::Academy::Pokedex::Advance.call(
            learner_id: learner_id, concept: from, mission: mission,
            trigger: :transfer_detected
          )

          detection
        end
      end
    end
  end
end
