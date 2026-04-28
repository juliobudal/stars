# frozen_string_literal: true

module Ui
  module Brand
    # Auth/onboarding logo lockup: yellow rounded tile + white star icon
    # + "LittleStars" wordmark, with optional eyebrow tagline above.
    #
    # Replaces the verbatim duplication in family_sessions/new,
    # profile_sessions/new, registrations/new, and missing brand on
    # password_resets/* and invitations/show. See
    # .planning/ui-reviews/20260428-audit/04-auth-shared.md §3, §5.
    #
    # API:
    #   render Ui::Brand::Component.new                            # md
    #   render Ui::Brand::Component.new(size: :lg, tagline: "...")
    class Component < ApplicationComponent
      SIZES = {
        sm: { tile: 36, radius: 10, icon: 18, wordmark: 16 },
        md: { tile: 48, radius: 14, icon: 26, wordmark: 22 },
        lg: { tile: 64, radius: 16, icon: 34, wordmark: 28 }
      }.freeze

      def initialize(size: :md, tagline: nil, **options)
        @size = SIZES.key?(size.to_sym) ? size.to_sym : :md
        @tagline = tagline
        @options = options
        super()
      end

      def spec
        SIZES[@size]
      end
    end
  end
end
