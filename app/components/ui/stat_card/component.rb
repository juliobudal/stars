# frozen_string_literal: true

module Ui
  module StatCard
    class Component < ApplicationComponent
      TINTS = {
        "star"    => { bg: "var(--star-soft)",     fg: "var(--c-amber-dark)",  border: "var(--star)" },
        "primary" => { bg: "var(--primary-soft)",  fg: "var(--primary)",       border: "var(--primary-glow)" },
        "rose"    => { bg: "var(--c-rose-soft)",   fg: "var(--c-rose)",        border: "var(--c-rose)" },
        "mint"    => { bg: "var(--c-mint-soft)",   fg: "var(--c-mint-dark)",   border: "var(--c-mint)" },
        "sky"     => { bg: "var(--c-sky-soft)",    fg: "var(--c-sky-dark)",    border: "var(--c-sky)" },
        "lilac"   => { bg: "var(--c-lilac-soft)",  fg: "var(--c-lilac-dark)",  border: "var(--c-lilac)" },
        "peach"   => { bg: "var(--c-peach-soft)",  fg: "var(--c-rose-dark)",   border: "var(--c-peach)" },
        "reward"  => { bg: "var(--star-soft)",     fg: "var(--c-reward-text)", border: "var(--star)" },
        "info"    => { bg: "var(--c-info-100)",    fg: "var(--c-info-600)",    border: "var(--c-info-500)" },
        "prize"   => { bg: "var(--c-rose-soft)",   fg: "var(--c-rose-dark)",   border: "var(--c-rose)" },
        "danger"  => { bg: "var(--c-red-soft)",    fg: "var(--danger)",        border: "oklch(from var(--danger) calc(l + 0.12) c h)" }
      }.freeze

      def initialize(value:, label:, icon:, tint: "primary")
        @value = value
        @label = label
        @icon = icon
        @tint = TINTS[tint.to_s] || TINTS["primary"]
        super()
      end

      attr_reader :value, :label, :icon, :tint
    end
  end
end
