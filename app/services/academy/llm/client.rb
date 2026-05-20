# frozen_string_literal: true

require "net/http"
require "json"

module Academy
  module Llm
    # Minimal OpenRouter client (OpenAI-compatible chat completions).
    # Thin, testable surface — OpenRouter speaks the OpenAI schema
    # directly. Used by Academy::Guide::Ask (kid chat).
    class Client
      class Error < StandardError; end

      # With max_tokens at 10k and reasoning models that emit hidden thought
      # tokens before output, a single call can exceed 60s on slow upstream.
      # 180s gives comfortable headroom; the loading overlay's failsafe
      # (75s in academy_loading_controller.js) is a lower-bound UX cap,
      # not a hard transport cap.
      DEFAULT_TIMEOUT = 180

      # Transient upstream errors get one retry with a short backoff. We
      # don't retry 4xx (caller bug or rate-limit signal we want to surface)
      # or timeouts (the request may have actually started and a duplicate
      # call would double-charge tokens).
      RETRYABLE_STATUSES = %w[502 503 504].freeze
      RETRY_BACKOFF_S    = 0.8

      def initialize(config: Academy.config, http_open_timeout: 5, http_read_timeout: DEFAULT_TIMEOUT)
        @config = config
        @http_open_timeout = http_open_timeout
        @http_read_timeout = http_read_timeout
      end

      # messages: [{ role: "system"|"user"|"assistant", content: "..." }, ...]
      # Optional overrides: model:, temperature:, max_tokens:, reasoning:.
      # Returns { content:, raw:, tokens: } or raises Client::Error.
      def chat(messages:, response_format: nil, model: nil, temperature: nil, max_tokens: nil, reasoning: { enabled: false })
        raise Error, "OPENROUTER_API_KEY not set" unless @config.openrouter_api_key.to_s.length > 8

        uri = URI.join(@config.openrouter_base_url + "/", "chat/completions")
        body = {
          model: model || @config.model,
          temperature: temperature || @config.temperature,
          max_tokens: max_tokens || @config.max_tokens,
          messages: messages,
          reasoning: reasoning
        }.compact
        body[:response_format] = response_format if response_format

        req = Net::HTTP::Post.new(uri)
        req["Content-Type"] = "application/json"
        req["Authorization"] = "Bearer #{@config.openrouter_api_key}"
        req["HTTP-Referer"]  = @config.referer if @config.referer.present?
        req["X-Title"]       = @config.app_title if @config.app_title.present?
        req.body = body.to_json

        res = perform_request_with_retry(uri, req)

        raise Error, "OpenRouter HTTP #{res.code}: #{res.body[0, 400]}" unless res.is_a?(Net::HTTPSuccess)

        parsed = JSON.parse(res.body)
        choice = parsed.dig("choices", 0, "message", "content")
        finish = parsed.dig("choices", 0, "finish_reason")
        raise Error, "Empty completion: #{parsed.inspect[0, 400]}" if choice.to_s.strip.empty?

        # Silent truncation is the #1 cause of "schema validation failed" loops.
        # Surface it so the retry layer can request a shorter / less verbose
        # output instead of guessing at the failure cause.
        if finish == "length"
          Rails.logger.warn(
            "[Academy::Llm::Client] truncated by max_tokens — model=#{body[:model]} " \
            "max_tokens=#{body[:max_tokens]} tokens_used=#{parsed.dig('usage', 'total_tokens')}"
          )
        end

        # Structured usage log — single line per LLM call so log aggregators
        # can compute cost / call rate / model mix without a separate ledger
        # table. Parse downstream; don't compute USD here (pricing drifts).
        Rails.logger.info(
          "[Academy::Llm::Usage] model=#{body[:model]} " \
          "in=#{parsed.dig('usage', 'prompt_tokens')} " \
          "out=#{parsed.dig('usage', 'completion_tokens')} " \
          "total=#{parsed.dig('usage', 'total_tokens')} " \
          "finish=#{finish}"
        )

        {
          content: choice,
          raw: parsed,
          tokens: parsed.dig("usage", "total_tokens"),
          finish_reason: finish
        }
      rescue JSON::ParserError => e
        raise Error, "Invalid JSON from OpenRouter: #{e.message}"
      end

      private

      # One retry for transient infra failures: 502/503/504 (upstream gateway
      # issues) or Net::OpenTimeout (never reached server, safe to repeat).
      # Read timeouts are NOT retried — the request may already be processing
      # upstream and we'd double-bill tokens.
      def perform_request_with_retry(uri, req)
        attempts = 0
        loop do
          attempts += 1
          res = begin
            do_request(uri, req)
          rescue Net::OpenTimeout => e
            raise Error, "OpenRouter open_timeout after #{attempts} attempts: #{e.message}" if attempts >= 2

            Rails.logger.warn("[Academy::Llm::Client] open_timeout — retrying once")
            sleep RETRY_BACKOFF_S
            next
          end

          return res unless RETRYABLE_STATUSES.include?(res.code) && attempts < 2

          Rails.logger.warn(
            "[Academy::Llm::Client] transient HTTP #{res.code} from upstream — retrying once"
          )
          sleep RETRY_BACKOFF_S
        end
      end

      def do_request(uri, req)
        Net::HTTP.start(uri.hostname, uri.port,
                        use_ssl: uri.scheme == "https",
                        open_timeout: @http_open_timeout,
                        read_timeout: @http_read_timeout) { |http| http.request(req) }
      end
    end
  end
end
