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
        message: error.message,
        context: context.presence
      }.compact

      # Tag-prefixed like the rest of the app's logs ("[Namespace] ...") so a
      # grep on the tag still finds these, with a JSON tail for structured
      # parsing.
      Rails.logger.error("[Observability::ErrorSubscriber] #{payload.to_json}")
    end
  end
end
