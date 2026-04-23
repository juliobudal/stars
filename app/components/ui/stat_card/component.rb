# frozen_string_literal: true

module Ui
  module StatCard
    class Component < ApplicationComponent
      TINTS = {
        "star"    => { bg: "var(--star-soft)",     fg: "var(--c-amber-dark)" },
        "primary" => { bg: "var(--primary-soft)",  fg: "var(--primary)"      },
        "rose"    => { bg: "var(--c-rose-soft)",   fg: "var(--c-rose)"       },
        "mint"    => { bg: "var(--c-mint-soft)",   fg: "var(--c-mint-dark)"  },
        "sky"     => { bg: "var(--c-sky-soft)",    fg: "var(--c-sky-dark)"   },
        "lilac"   => { bg: "var(--c-lilac-soft)",  fg: "var(--c-lilac-dark)" },
        "peach"   => { bg: "var(--c-peach-soft)",  fg: "var(--c-rose-dark)"  }
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
