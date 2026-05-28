# frozen_string_literal: true

# First-session onboarding for kids. Four focused screens (welcome,
# interests, how_it_works, ready) end with `finish` which stamps
# `profiles.onboarded_at`. Re-entrant: the kid can come back to any step
# until `finish` succeeds. The whole controller opts out of the guard so
# un-onboarded kids can reach it without looping.
module Kid
  class OnboardingController < Kid::BaseController
    skip_before_action :gate_kid_onboarding!

    layout "kid_onboarding"

    MIN_PICKS = 3
    MAX_PICKS = 5

    def welcome
      @step = 1
    end

    def interests
      @step = 2
      @catalog = ::ProfileInterest::Catalog.all
      @selected = current_profile.interest_keys(MAX_PICKS)
      @min = MIN_PICKS
      @max = MAX_PICKS
    end

    def update_interests
      keys = Array(params[:interest_keys]).map(&:to_s).uniq
      keys = keys.select { |k| ::ProfileInterest::Catalog.find(k) }
      keys = keys.first(MAX_PICKS)

      if keys.size < MIN_PICKS
        @step = 2
        @catalog = ::ProfileInterest::Catalog.all
        @selected = keys
        @min = MIN_PICKS
        @max = MAX_PICKS
        flash.now[:alert] = "Escolhe ao menos #{MIN_PICKS} coisas que você curte!"
        return render :interests, status: :unprocessable_content
      end

      ActiveRecord::Base.transaction do
        current_profile.profile_interests.delete_all
        keys.each_with_index do |key, idx|
          current_profile.profile_interests.create!(interest_key: key, rank: idx + 1)
        end
      end

      redirect_to kid_welcome_how_path
    end

    def how_it_works
      @step = 3
    end

    def ready
      @step = 4
    end

    def finish
      current_profile.update!(onboarded_at: Time.current)
      redirect_to kid_root_path, notice: "Tudo pronto, #{current_profile.name}! ✨"
    end
  end
end
