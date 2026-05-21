# frozen_string_literal: true

require "image_processing/mini_magick"

module Academy
  module Illustrations
    # Generates one illustration for a LensCache row that carries an
    # `illustration_hint` in its payload. Calls OpenRouter via
    # Illustrations::Client, optimizes the bytes to WebP at most 1024×1024
    # quality 85, writes the file under public/academy/illustrations/, and
    # records `illustration_url` + `illustration_meta` back into the payload.
    #
    # Uses ImageProcessing::MiniMagick (ImageMagick) rather than Vips because
    # the dev/CI Docker image ships ImageMagick 7 but not libvips. Both
    # backends produce equivalent WebP output for this use case.
    #
    # Idempotent: a row already up-to-date (URL set, file present, meta.style
    # matching STYLE_VERSION) returns `ok(skipped: true)` without an API call.
    # Pass `force: true` to regenerate anyway.
    class Generate < ApplicationService
      OUTPUT_DIR = Rails.root.join("public/academy/illustrations").freeze
      MAX_DIMENSION = 1024
      WEBP_QUALITY = 85

      def initialize(lens_cache:, client: nil, force: false)
        @lens_cache = lens_cache
        @client = client || Client.new
        @force = force
      end

      def call
        return fail_with(:no_api_key) unless Academy.config.openrouter_api_key.to_s.length > 8

        hint = @lens_cache.payload["illustration_hint"].to_s
        return fail_with(:missing_hint) if hint.empty?

        slug = resolve_slug
        return fail_with(:missing_slug) if slug.empty?

        path = OUTPUT_DIR.join("#{slug}.webp")
        url = "/academy/illustrations/#{slug}.webp"

        if !@force && up_to_date?(path: path)
          return ok(skipped: true, slug: slug, url: url)
        end

        prompt = PromptComposer.compose(hint: hint)
        response = @client.generate(prompt: prompt)

        webp_bytes = optimize_to_webp(response[:bytes])

        FileUtils.mkdir_p(OUTPUT_DIR)
        File.binwrite(path, webp_bytes)

        @lens_cache.payload = @lens_cache.payload.merge(
          "illustration_url" => url,
          "illustration_meta" => {
            "style" => PromptComposer::STYLE_VERSION,
            "model" => response[:model],
            "generated_at" => Time.current.iso8601
          }
        )
        @lens_cache.save!

        ok(skipped: false, slug: slug, url: url, bytes_written: webp_bytes.bytesize, model: response[:model])
      rescue Client::Error => e
        fail_with(:client_error, data: { message: e.message })
      end

      private

      def resolve_slug
        concept = @lens_cache.concept
        return "" unless concept

        (concept.try(:slug).presence || concept.name.to_s.parameterize(separator: "-")).to_s
      end

      def up_to_date?(path:)
        meta = @lens_cache.payload["illustration_meta"] || {}
        @lens_cache.payload["illustration_url"].present? &&
          File.exist?(path) &&
          meta["style"] == PromptComposer::STYLE_VERSION
      end

      def optimize_to_webp(input_bytes)
        Tempfile.create([ "pill-illustration-source", ".bin" ], binmode: true) do |source|
          source.write(input_bytes)
          source.flush

          processed = ImageProcessing::MiniMagick
            .source(source.path)
            .resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
            .convert("webp")
            .saver(quality: WEBP_QUALITY)
            .call
          begin
            processed.read
          ensure
            processed.close
            processed.unlink
          end
        end
      end
    end
  end
end
