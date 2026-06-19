# frozen_string_literal: true

module Ledger
  # Expires unused stars for families that opted into decay — the behavior the
  # parent settings toggle already promises ("Estrelas não usadas expiram após
  # 30 dias") but that previously had no implementation behind it.
  #
  # For each child, every `earn` ledger entry older than DECAY_AFTER that has
  # never been decayed is marked (its `decayed_at` is set — the partial index
  # `index_activity_logs_undecayed_earns` is built for exactly this lookup) and
  # its still-unspent value is removed from the balance via a single signed
  # `:decay` log. The deduction is capped at the current balance, so already
  # spent stars never decay twice and the balance never goes negative.
  #
  # Ledger-consistent by construction: a −deduction `:decay` log plus a
  # matching points decrement keeps the Ledger::ReconcileService invariant
  #
  #   profile.points == profile.activity_logs.sum(:points)
  #
  # holding, so reconciliation needs no special-casing. Opt-in + idempotent:
  # a no-op unless `family.decay_enabled?`, and the `decayed_at` marker makes
  # repeat runs safe.
  class DecayService < ApplicationService
    DECAY_AFTER = 30.days

    def initialize(family:, now: Time.current)
      raise ArgumentError, "family is required" unless family
      @family = family
      @now = now
    end

    def call
      return ok(decayed: 0, profiles: 0) unless @family.decay_enabled?

      cutoff = @now - DECAY_AFTER
      total_decayed = 0
      profiles_touched = 0

      @family.profiles.where(role: Profile.roles[:child]).find_each do |profile|
        deducted = decay_profile(profile, cutoff)
        if deducted.positive?
          total_decayed += deducted
          profiles_touched += 1
        end
      end

      Rails.logger.info("[Ledger::DecayService] family_id=#{@family.id} decayed=#{total_decayed} profiles=#{profiles_touched}")
      ok(decayed: total_decayed, profiles: profiles_touched)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Ledger::DecayService] exception family_id=#{@family.id} error=#{e.message}")
      fail_with(e.message)
    end

    private

    # Returns the points actually removed from this profile (0 when nothing
    # qualified). Locked per-profile so it can't race a concurrent
    # approve/redeem that also mutates points.
    def decay_profile(profile, cutoff)
      ActiveRecord::Base.transaction do
        profile.lock!

        stale_earns = profile.activity_logs
                             .where(log_type: ActivityLog.log_types[:earn], decayed_at: nil)
                             .where(created_at: ..cutoff)

        decay_total = stale_earns.sum(:points)
        marked = stale_earns.update_all(decayed_at: @now)
        next 0 if marked.zero?

        deduction = [ decay_total, profile.points.to_i ].min
        next 0 unless deduction.positive?

        profile.decrement!(:points, deduction)
        ActivityLog.create!(
          profile: profile,
          log_type: :decay,
          title: "Estrelas expiradas (#{(DECAY_AFTER / 1.day).to_i} dias)",
          points: -deduction
        )
        deduction
      end
    end
  end
end
