# frozen_string_literal: true

module Ui
  module HeaderStatChip
    # Inline corner-stat chip for parent page-header right slots.
    # Examples: "5 dias seguidos" (streak), "3 pendentes" (approvals),
    # "12 eventos hoje" (activity). Three near-identical inline blocks
    # in dashboard, approvals, activity_logs collapse here. See
    # .planning/ui-reviews/20260428-audit/03-parent-surfaces.md §6/§7.
    #
    # Variants drive color tokens only; geometry stays constant.
    class Component < ApplicationComponent
      VARIANTS = {
        default: {
          bg: "var(--surface)",
          border: "var(--hairline)",
          shadow: "var(--text-soft)",
          value_color: "var(--text)",
          label_color: "var(--text-muted)",
          icon_color: "var(--text-muted)"
        },
        warning: {
          bg: "var(--star-soft)",
          border: "var(--star)",
          shadow: "var(--star-2)",
          value_color: "var(--c-streak)",
          label_color: "var(--c-amber-dark)",
          icon_color: "var(--c-streak)"
        },
        success: {
          bg: "var(--primary-soft)",
          border: "var(--primary)",
          shadow: "var(--primary-2)",
          value_color: "var(--primary-2)",
          label_color: "var(--primary-2)",
          icon_color: "var(--primary-2)"
        },
        danger: {
          bg: "var(--c-rose-soft)",
          border: "var(--danger)",
          shadow: "var(--danger-2)",
          value_color: "var(--danger)",
          label_color: "var(--danger-2)",
          icon_color: "var(--danger)"
        }
      }.freeze

      def initialize(label:, value:, icon: nil, variant: :default, value_id: nil, **options)
        @label = label
        @value = value
        @icon = icon
        @value_id = value_id
        key = variant.to_sym
        @variant = VARIANTS.key?(key) ? key : :default
        @options = options
        super()
      end

      attr_reader :value_id

      def tokens
        VARIANTS[@variant]
      end
    end
  end
end
