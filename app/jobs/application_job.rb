class ApplicationJob < ActiveJob::Base
  # Transient infra failures self-heal instead of dying silently.
  retry_on ActiveRecord::Deadlocked, attempts: 3

  # A job whose underlying record was deleted before it ran can never succeed.
  discard_on ActiveJob::DeserializationError
end
