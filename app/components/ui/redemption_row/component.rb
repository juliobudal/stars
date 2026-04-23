# frozen_string_literal: true

module Ui
  module RedemptionRow
    class Component < ApplicationComponent
      STATUS_MAP = {
        "pending"  => { label: "Disponível", bg: "var(--c-lilac-soft)", fg: "var(--primary-2)" },
        "approved" => { label: "Aproveitado", bg: "var(--c-mint-soft)", fg: "var(--c-mint-dark)" },
        "rejected" => { label: "Recusado", bg: "var(--c-rose-soft)", fg: "var(--c-rose-dark)" }
      }.freeze

      def initialize(redemption:)
        @redemption = redemption
        super()
      end

      attr_reader :redemption

      def icon
        r = redemption.reward
        (r.respond_to?(:icon) ? r.icon.presence : nil) || "gift"
      end

      def status_key
        return "pending"  if redemption.respond_to?(:pending?)  && redemption.pending?
        return "approved" if redemption.respond_to?(:approved?) && redemption.approved?
        return "rejected" if redemption.respond_to?(:rejected?) && redemption.rejected?
        "pending"
      end

      def status
        STATUS_MAP[status_key] || STATUS_MAP["pending"]
      end
    end
  end
end
