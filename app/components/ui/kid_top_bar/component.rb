# frozen_string_literal: true

module Ui
  module KidTopBar
    # Kid-shell header: streak badge + balance chip + profile-switch.
    # Replaces the bespoke headers on dashboard, rewards, missions/new
    # (wallet uses Ui::TopBar instead). See
    # .planning/ui-reviews/20260428-audit/02-kid-surfaces.md §6, top-fix #3.
    #
    # The balance span is rendered with a stable id of
    # `profile_points_<id>` and `aria-live="polite"` so Profile model
    # broadcasts (Profile#broadcast_update_to ... target:
    # "profile_points_<id>") still update the live count and screen
    # readers announce changes.
    class Component < ApplicationComponent
      def initialize(profile:, streak: nil, show_streak: true, show_balance: true, show_switch: true, switch_url: nil, **options)
        @profile = profile
        @streak_override = streak
        @show_streak = show_streak
        @show_balance = show_balance
        @show_switch = show_switch
        @switch_url = switch_url
        @options = options
        super()
      end

      def streak
        return @streak_override.to_i unless @streak_override.nil?
        @profile.respond_to?(:streak) ? @profile.streak.to_i : 0
      end

      def points
        @profile.respond_to?(:points) ? @profile.points.to_i : 0
      end
    end
  end
end
