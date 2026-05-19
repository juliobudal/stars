# frozen_string_literal: true

module Academy
  module Llm
    # Calls the configured judge model (default gpt-5-nano via OpenRouter)
    # to grade a generated lens payload against the v4 rubric — factual /
    # concept-fidelity / safety only. Tone and didactics are template-owned.
    #
    # Stateless. Returns a Verdict value object. Raises JudgeError on
    # transport or parse failure — callers should treat as "judge unavailable",
    # not as a quality failure. The lens generator pipeline catches
    # JudgeError and ships the lens with `judge_verdict="skipped"` rather
    # than blocking the kid.
    #
    # Score scale: 0..100 (v4). Old v3 cache rows use 0..12 — the new
    # example_picker floor (85) excludes them naturally, so v3 judgments
    # don't pollute the few-shot pool after the rubric shift.
    class Judge
      class JudgeError < StandardError; end

      Verdict = Data.define(
        :score, :verdict, :critique, :rewrite_hint,
        :factual_issue, :concept_drift, :safety_issue, :raw_json
      ) do
        def pass?   = verdict == "PASS"
        def fail?   = verdict == "FAIL"
        def revise? = verdict == "REVISE"

        # True when the generator should re-run with `rewrite_hint`.
        # Includes FAIL because we still give it one shot — only if the
        # second attempt also fails does the generator give up.
        def needs_revision?
          revise? || fail?
        end

        # Safety hard-failed regardless of overall score.
        def unsafe?
          safety_issue.present?
        end
      end

      def initialize(client: Client.new, config: Academy.config)
        @client = client
        @config = config
      end

      # Judges a single generated lens payload.
      #
      # @param concept   [Academy::Concept-like]
      # @param lens_type [Symbol] one of Academy::Lens::Catalog.types
      # @param payload   [Hash]   schema-validated lens payload
      # @param age_band  [String] "kid" by default
      # @return [Verdict]
      # @raise [JudgeError] on transport or unparseable response
      def judge(concept:, lens_type:, payload:, age_band: "kid")
        messages = [
          { role: "system", content: JudgePersona::VOICE },
          { role: "user",   content: JudgePersona.user_prompt(
            concept: concept, lens_type: lens_type, payload: payload, age_band: age_band
          ) }
        ]
        result = @client.chat(
          messages: messages,
          response_format: { type: "json_object" },
          model: @config.judge_model,
          temperature: @config.judge_temperature,
          max_tokens: @config.judge_max_tokens,
          reasoning: { effort: @config.judge_reasoning_effort }
        )
        parse(result[:content])
      rescue Client::Error => e
        raise JudgeError, "judge LLM call failed: #{e.message}"
      end

      private

      def parse(text)
        json = extract_json(text)
        parsed = JSON.parse(json)

        Verdict.new(
          score:         parsed["score"].to_i,
          verdict:       parsed["verdict"].to_s.upcase,
          critique:      parsed["critique"].presence,
          rewrite_hint:  parsed["rewrite_hint"].presence,
          factual_issue: parsed["factual_issue"].presence,
          concept_drift: parsed["concept_drift"].presence,
          safety_issue:  parsed["safety_issue"].presence,
          raw_json:      parsed
        )
      rescue JSON::ParserError => e
        raise JudgeError, "judge returned invalid JSON: #{e.message}\n---\n#{text.to_s[0, 300]}"
      end

      # Tolerant JSON extractor — strips ```json fences or surrounding prose
      # so a slightly chatty judge response still parses cleanly.
      def extract_json(text)
        stripped = text.to_s.strip
        return stripped if stripped.start_with?("{")

        m = stripped.match(/```(?:json)?\s*(\{.*?\})\s*```/m)
        return m[1] if m

        m = stripped.match(/(\{.*\})/m)
        return m[1] if m

        stripped
      end
    end
  end
end
