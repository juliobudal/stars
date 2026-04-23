# frozen_string_literal: true

module Ui
  module HistoryRow
    class Component < ApplicationComponent
      TYPE_MAP = {
        "earn"   => { icon: "sparkle", disc_bg: "var(--c-mint-soft)",  disc_color: "var(--c-mint-dark)", chip_bg: "var(--c-mint-soft)",  chip_text: "var(--c-mint-dark)",  label: "Conquista" },
        "redeem" => { icon: "gift",    disc_bg: "var(--c-lilac-soft)", disc_color: "var(--primary)",     chip_bg: "var(--c-lilac-soft)", chip_text: "var(--primary-2)",    label: "Compra"    },
        "adjust" => { icon: "star",    disc_bg: "var(--star-soft)",    disc_color: "var(--star-2)",      chip_bg: "var(--star-soft)",    chip_text: "var(--star-2)",       label: "Ajuste"    }
      }.freeze

      def initialize(log:, with_divider: true)
        @log = log
        @with_divider = with_divider
        super()
      end

      attr_reader :log, :with_divider

      def kind
        TYPE_MAP[log.log_type.to_s] || TYPE_MAP["adjust"]
      end

      def points_color
        log.earn? ? "var(--c-mint-dark)" : "var(--c-rose-dark)"
      end

      def points_sign
        log.earn? ? "+" : "−"
      end
    end
  end
end
