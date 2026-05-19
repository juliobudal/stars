# frozen_string_literal: true

module Academy
  module Transfer
    # Async wrapper for Transfer::Detect. Queued by Academy::Message after
    # creating a learner free-text turn.
    class DetectJob < ApplicationJob
      queue_as :default

      retry_on Llm::Client::Error, wait: :polynomially_longer, attempts: 3

      def perform(message_id)
        message = ::Academy::Message.find_by(id: message_id)
        return unless message

        Transfer::Detect.call(message: message)
      end
    end
  end
end
