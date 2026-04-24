# frozen_string_literal: true

module Ui
  module HistoryRow
    class Component < ApplicationComponent
      TYPE_MAP = {
        "earn"   => { icon: "sparkle", disc_bg: "bg-mint-soft",  disc_color: "text-mint-dark", chip_bg: "bg-mint-soft",  chip_text: "text-mint-dark",  label: "Conquista", chip_variant: "mint"   },
        "redeem" => { icon: "gift",    disc_bg: "bg-lilac-soft", disc_color: "text-[var(--primary)]",     chip_bg: "bg-lilac-soft", chip_text: "text-[var(--primary-2)]",    label: "Compra",    chip_variant: "lilac"  },
        "adjust" => { icon: "star",    disc_bg: "bg-star-soft",    disc_color: "text-[var(--star-2)]",      chip_bg: "bg-star-soft",    chip_text: "text-[var(--star-2)]",       label: "Ajuste",    chip_variant: "star"   }
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
        log.earn? ? "text-mint-dark" : "text-rose-dark"
      end

      def points_sign
        log.earn? ? "+" : "−"
      end
    end
  end
end
