# frozen_string_literal: true

module Ui
  # Centralizes Turbo Stream broadcasts to a profile's signed "fx_stage"
  # channel. Services and model callbacks call this instead of invoking
  # Turbo::StreamsChannel directly, so the channel naming/signing strategy
  # stays in one place.
  class FxBroadcaster
    def self.celebrate(profile:, tier:, payload:)
      append(profile: profile, target: "fx_stage", partial: "kid/shared/celebration",
             locals: { tier: tier, payload: payload })
    end

    def self.append(profile:, target:, partial:, locals: {})
      Turbo::StreamsChannel.broadcast_append_to(
        profile, "fx_stage",
        target: target, partial: partial, locals: locals
      )
    rescue StandardError => e
      Rails.logger.warn("[Ui::FxBroadcaster] append failed profile_id=#{profile&.id} error=#{e.message}")
    end

    def self.replace(profile:, target:, partial:, locals: {})
      Turbo::StreamsChannel.broadcast_replace_to(
        profile, "fx_stage",
        target: target, partial: partial, locals: locals
      )
    rescue StandardError => e
      Rails.logger.warn("[Ui::FxBroadcaster] replace failed profile_id=#{profile&.id} error=#{e.message}")
    end
  end
end
