module Profiles
  class SetWishlistService < ApplicationService
    def initialize(profile:, reward:)
      @profile = profile
      @reward = reward # may be nil to clear
    end

    def call
      Rails.logger.info(
        "[Profiles::SetWishlistService] start profile_id=#{@profile.id} reward_id=#{@reward&.id.inspect}"
      )

      if @reward && @reward.family_id != @profile.family_id
        Rails.logger.info("[Profiles::SetWishlistService] failure cross_family")
        return fail_with("Reward não pertence a esta família")
      end

      ActiveRecord::Base.transaction do
        @profile.update!(wishlist_reward: @reward)
      end

      Rails.logger.info("[Profiles::SetWishlistService] success profile_id=#{@profile.id} reward_id=#{@reward&.id.inspect}")
      ok({ profile: @profile, reward: @reward })
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Profiles::SetWishlistService] exception #{e.message}")
      fail_with(e.message)
    end
  end
end
