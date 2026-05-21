# frozen_string_literal: true

require "net/http"
require "json"
require "base64"

module Academy
  module Illustrations
    # OpenRouter image-generation client. Uses chat completions with the
    # multimodal output endpoint, returning bytes for a single image.
    #
    # Used only by Academy::Illustrations::Generate during the one-shot
    # rake pipeline — never on the kid's runtime path.
    class Client
      class Error < StandardError; end

      # Image generation is slower than text; OpenRouter providers like
      # Gemini Flash Image typically respond in 5-20s, with tail latency
      # up to ~90s. 180s gives comfortable headroom.
      DEFAULT_TIMEOUT = 180

      RETRYABLE_STATUSES = %w[502 503 504].freeze
      RETRY_BACKOFF_S    = 1.5

      def initialize(config: Academy.config, http_open_timeout: 5, http_read_timeout: DEFAULT_TIMEOUT)
        @config = config
        @http_open_timeout = http_open_timeout
        @http_read_timeout = http_read_timeout
      end

      # prompt: composed prompt string (PromptComposer output).
      # Returns { mime:, bytes:, model:, raw: } or raises Client::Error.
      def generate(prompt:, model: nil, aspect_ratio: nil, image_size: nil)
        raise Error, "OPENROUTER_API_KEY not set" unless @config.openrouter_api_key.to_s.length > 8

        used_model = model || @config.image_model
        uri = URI.join(@config.openrouter_base_url + "/", "chat/completions")
        body = {
          model: used_model,
          modalities: %w[image text],
          messages: [ { role: "user", content: prompt } ],
          image_config: {
            aspect_ratio: aspect_ratio || @config.image_aspect_ratio,
            image_size: image_size || @config.image_size
          }
        }

        req = Net::HTTP::Post.new(uri)
        req["Content-Type"] = "application/json"
        req["Authorization"] = "Bearer #{@config.openrouter_api_key}"
        req["HTTP-Referer"]  = @config.referer if @config.referer.present?
        req["X-Title"]       = @config.app_title if @config.app_title.present?
        req.body = body.to_json

        res = perform_request_with_retry(uri, req)

        raise Error, "OpenRouter HTTP #{res.code}: #{res.body[0, 400]}" unless res.is_a?(Net::HTTPSuccess)

        parsed = JSON.parse(res.body)
        data_url = parsed.dig("choices", 0, "message", "images", 0, "image_url", "url")
        raise Error, "Response missing images[0].image_url.url: #{parsed.inspect[0, 400]}" if data_url.to_s.strip.empty?

        mime, bytes = parse_data_url(data_url)

        Rails.logger.info(
          "[Academy::Illustrations::Usage] model=#{used_model} " \
          "in=#{parsed.dig('usage', 'prompt_tokens')} " \
          "out=#{parsed.dig('usage', 'completion_tokens')} " \
          "total=#{parsed.dig('usage', 'total_tokens')} " \
          "bytes=#{bytes.bytesize}"
        )

        { mime: mime, bytes: bytes, model: used_model, raw: parsed }
      rescue JSON::ParserError => e
        raise Error, "Invalid JSON from OpenRouter: #{e.message}"
      end

      private

      def parse_data_url(data_url)
        unless (m = data_url.match(%r{\Adata:(image/[a-z+.-]+);base64,(.*)\z}m))
          raise Error, "Malformed data URL prefix: #{data_url[0, 80]}..."
        end

        mime = m[1]
        bytes = Base64.decode64(m[2])
        raise Error, "Decoded image is empty" if bytes.empty?

        [ mime, bytes ]
      end

      def perform_request_with_retry(uri, req)
        attempts = 0
        loop do
          attempts += 1
          res = begin
            do_request(uri, req)
          rescue Net::OpenTimeout, Net::ReadTimeout => e
            raise Error, "OpenRouter timeout after #{attempts} attempts: #{e.message}" if attempts >= 3

            Rails.logger.warn("[Academy::Illustrations::Client] timeout — retrying (#{attempts}/2)")
            sleep RETRY_BACKOFF_S
            next
          end

          return res unless RETRYABLE_STATUSES.include?(res.code) && attempts < 3

          Rails.logger.warn(
            "[Academy::Illustrations::Client] transient HTTP #{res.code} — retrying (#{attempts}/2)"
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
