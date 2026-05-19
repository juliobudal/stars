# frozen_string_literal: true

module Academy
  module Wagers
    # v5 transitional stub. The v4 PracticeWager creation flow lived
    # inside the chat-based AdvanceTurn finalize chain on `discovery`
    # missions. v5 retires that path and will rewire wagers through the
    # `statistical` lens (Phase 2+, T-V5-045/051). Until then, this
    # service preserves its public contract but no-ops safely so any
    # transitional caller stays green.
    class Create < ApplicationService
      def initialize(progress:)
        @progress = progress
      end

      def call
        ok(nil)
      end
    end
  end
end
