# frozen_string_literal: true

# Route every exception reported via the Rails.error API to our structured
# subscriber. Wrapped in after_initialize so the autoloaded constant is ready.
# To add an external error tracker later, subscribe its handler here too —
# Rails fans out to all subscribers.
Rails.application.config.after_initialize do
  Rails.error.subscribe(Observability::ErrorSubscriber.new)
end
