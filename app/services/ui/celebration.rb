module Ui
  module Celebration
    BIG_EVENTS = %i[approved redeemed streak threshold all_cleared].freeze
    SMALL_EVENTS = %i[done_tapped reset reward_unlocked].freeze

    def self.tier_for(event_type, **_context)
      sym = event_type.to_sym
      return :big if BIG_EVENTS.include?(sym)
      return :small if SMALL_EVENTS.include?(sym)

      :none
    end
  end
end
