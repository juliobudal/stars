# frozen_string_literal: true

# Kid-facing "Eu curto" surface. Lets the child pick 3-5 interests from the
# canonical catalog (config/profile_interests.yml). The picks are persisted
# as ProfileInterest rows ordered by click — the top pick drives interest
# variants of curated Academy payloads.
module Kid
  class InterestsController < ApplicationController
    include Authenticatable

    before_action :require_child!
    layout "kid"

    MIN_PICKS = 3
    MAX_PICKS = 5

    def show
      @catalog = ::ProfileInterest::Catalog.all
      @selected = current_profile.interest_keys(MAX_PICKS)
      @min = MIN_PICKS
      @max = MAX_PICKS
    end

    def update
      keys = Array(params[:interest_keys]).map(&:to_s).uniq
      keys = keys.select { |k| ::ProfileInterest::Catalog.find(k) }
      keys = keys.first(MAX_PICKS)

      if keys.size < MIN_PICKS
        flash.now[:alert] = "Escolhe ao menos #{MIN_PICKS} coisas que você curte!"
        @catalog = ::ProfileInterest::Catalog.all
        @selected = keys
        @min = MIN_PICKS
        @max = MAX_PICKS
        return render :show, status: :unprocessable_entity
      end

      ActiveRecord::Base.transaction do
        current_profile.profile_interests.delete_all
        keys.each_with_index do |key, idx|
          current_profile.profile_interests.create!(interest_key: key, rank: idx + 1)
        end
      end

      redirect_to kid_root_path, notice: "Beleza, salvei seus gostos!"
    end
  end
end
