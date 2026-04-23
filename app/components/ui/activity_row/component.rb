# frozen_string_literal: true

module Ui
  module ActivityRow
    class Component < ApplicationComponent
      def initialize(log: nil, kid: nil, description: nil, timestamp: nil,
                     amount: nil, direction: nil, with_divider: true)
        if log
          @kid = log.profile
          raw_amount = log.respond_to?(:amount) ? log.amount : log.points
          amt = raw_amount.to_i
          amt = -amt.abs if log.log_type.to_s == "redeem" && amt > 0
          @amount = amt
          @direction = amt >= 0 ? "earn" : "spend"
          @description = if log.respond_to?(:description) && log.description.present?
                           log.description
          elsif log.respond_to?(:title) && log.title.present?
                           log.title
          else
                           log.log_type.to_s.humanize
          end
          @timestamp = log.created_at
        else
          @kid = kid
          @description = description
          @timestamp = timestamp
          @amount = amount.to_i
          @direction = direction.to_s.presence || (@amount >= 0 ? "earn" : "spend")
        end
        @with_divider = with_divider
        super()
      end

      attr_reader :kid, :description, :timestamp, :amount, :direction, :with_divider

      def amount_color
        direction == "spend" ? "var(--c-rose-dark)" : "var(--c-mint-dark)"
      end

      def amount_sign
        amount >= 0 ? "+" : "−"
      end
    end
  end
end
