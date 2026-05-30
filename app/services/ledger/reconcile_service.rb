# frozen_string_literal: true

module Ledger
  # Integrity check on the star economy. Profile.points is a mutable cache;
  # ActivityLog is the append-only signed ledger — its `points` column is the
  # SIGNED delta (earn → +, redeem → −, adjust refund → +). Every points
  # mutation writes a matching log: Tasks::ApproveService (earn),
  # Rewards::RedeemService (redeem), Rewards::RejectRedemptionService (adjust).
  # Collective redemptions log points:0 and never touch individual balances, and
  # streak detection awards no points — so the invariant
  #
  #   profile.points == profile.activity_logs.sum(:points)
  #
  # must always hold. This service reports drift via the Result; it does NOT
  # auto-correct, because a mismatch is a bug to investigate, not to patch over.
  #
  # ok(data: []) when the ledger is consistent; ok(data: [{profile_id, points,
  # ledger, diff}, ...]) listing every divergent profile otherwise.
  class ReconcileService < ApplicationService
    def call
      # One grouped query for the whole ledger instead of a SUM per profile.
      ledger_by_profile = ActivityLog.group(:profile_id).sum(:points)
      discrepancies = []

      Profile.find_each do |profile|
        points = profile.points.to_i # points is nullable; mirror the model's defensive to_i
        ledger = ledger_by_profile[profile.id].to_i
        next if ledger == points

        discrepancies << { profile_id: profile.id, points: points, ledger: ledger, diff: points - ledger }
      end

      ok(discrepancies)
    end
  end
end
