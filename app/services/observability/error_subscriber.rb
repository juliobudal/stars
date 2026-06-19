# frozen_string_literal: true

module Observability
  # Receives every exception reported through the Rails.error API and emits one
  # structured log line with severity + context. This is the single seam for
  # wiring an external tracker (Sentry/Honeybadger/Rollbar) later: register
  # their subscriber alongside this one in config/initializers/error_reporting.rb
  # and nothing else in the app has to change.
  class ErrorSubscriber
    def report(error, handled:, severity:, context:, source: nil)
      payload = {
        event: "error_report",
        severity: severity,
        handled: handled,
        source: source,
        error: error.class.name,
        message: error.message.to_s.truncate(500),
        context: safe_context(context)
      }.compact

      # Tag-prefixed like the rest of the app's logs ("[Namespace] ...") so a
      # grep on the tag still finds these, with a JSON tail for structured
      # parsing.
      Rails.logger.error("[Observability::ErrorSubscriber] #{payload.to_json}")
    rescue StandardError, SystemStackError => e
      # Reporting an error must NEVER raise — that masks the original error
      # (and previously turned a circular/huge context into a confusing
      # SystemStackError from to_json). Fall back to a plain line.
      Rails.logger.error(
        "[Observability::ErrorSubscriber] #{error.class}: #{error.message} " \
        "(structured report skipped: #{e.class})"
      )
    end

    private

    # `context` can carry arbitrary, possibly circular or deeply nested objects
    # (a Rack env, an AR record with its associations). Flatten to JSON-safe
    # scalars so serialization can't recurse into a stack overflow.
    def safe_context(context)
      return nil if context.blank?

      hash = context.respond_to?(:to_h) ? context.to_h : { value: context }
      hash.transform_values do |v|
        case v
        when String, Symbol, Numeric, true, false, nil then v
        else v.to_s.truncate(200)
        end
      end
    rescue StandardError
      nil
    end
  end
end
