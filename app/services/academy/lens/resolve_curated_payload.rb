# frozen_string_literal: true

module Academy
  module Lens
    # Picks the best curated `LensCache` row for a learner+concept+lens_type.
    #
    # Preference order:
    #   1. Variant matching the learner's TOP interest_key (one of the keys
    #      from config/profile_interests.yml).
    #   2. Default row — same composite key with interest_key IS NULL.
    #
    # Returns nil when neither exists. Callers (Generate / AdvanceLens)
    # convert nil into a `:no_curated_payload` failure.
    #
    # The learner argument can be:
    #   * an `Academy::Learner` value object (preferred — already has interests),
    #   * an object responding to `#interest_keys` (e.g. host Profile),
    #   * nil (no personalization — default lookup only).
    class ResolveCuratedPayload < ApplicationService
      def initialize(concept:, lens_type:, age_band: "kid", locale: "pt-BR", learner: nil)
        @concept   = concept
        @lens_type = lens_type.to_s
        @age_band  = age_band
        @locale    = locale
        @learner   = learner
      end

      def call
        row = lookup_for_interest(top_interest_key) || lookup_default
        return fail_with(:no_curated_payload, data: lookup_key) unless row

        ok(row)
      end

      private

      def base_scope
        ::Academy::LensCache.servable.curated.where(
          concept_id: @concept.id,
          lens_type:  @lens_type,
          age_band:   @age_band,
          locale:     @locale
        )
      end

      def lookup_for_interest(key)
        return nil if key.blank?

        base_scope.where(interest_key: key).order(updated_at: :desc).first
      end

      def lookup_default
        base_scope.where(interest_key: nil).order(updated_at: :desc).first
      end

      def top_interest_key
        return nil unless @learner

        if @learner.respond_to?(:top_interest_key)
          @learner.top_interest_key
        elsif @learner.respond_to?(:interests)
          first = Array(@learner.interests).first
          first.respond_to?(:key) ? first.key : first&.to_s
        elsif @learner.respond_to?(:interest_keys)
          Array(@learner.interest_keys).first
        end
      end

      def lookup_key
        {
          concept_id: @concept.id, lens_type: @lens_type,
          age_band: @age_band, locale: @locale,
          interest_key: top_interest_key
        }
      end
    end
  end
end
