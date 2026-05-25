# frozen_string_literal: true

module Ui
  module ShortcutCard
    # Tappable navigation card used across kid pages for "go-to" shortcuts:
    # Pílula do Dia, Lightning Round, Eu curto, Elenco, add-custom-mission, etc.
    # Replaces 6+ near-identical inline blocks that drifted on padding, radius,
    # and shadow depth. Geometry is fixed; tint switches the color tokens.
    class Component < ApplicationComponent
      TINTS = {
        primary: {
          bg:        "linear-gradient(135deg, var(--primary-soft) 0%, var(--surface) 70%)",
          border:    "var(--primary)",
          shadow:    "var(--primary-2)",
          eyebrow:   "var(--primary)",
          title:     "var(--text)",
          chevron:   "var(--primary)",
          icon_bg:   "var(--surface)",
          icon_brd:  "var(--primary)"
        },
        amber: {
          bg:        "var(--c-amber-soft)",
          border:    "var(--c-amber)",
          shadow:    "var(--c-amber-dark)",
          eyebrow:   "var(--c-amber-dark)",
          title:     "var(--text)",
          chevron:   "var(--c-amber-dark)",
          icon_bg:   "var(--surface)",
          icon_brd:  "var(--c-amber)"
        },
        neutral: {
          bg:        "var(--surface)",
          border:    "var(--hairline)",
          shadow:    "rgba(0,0,0,0.08)",
          eyebrow:   "var(--text-muted)",
          title:     "var(--text)",
          chevron:   "var(--text-muted)",
          icon_bg:   "var(--surface-2)",
          icon_brd:  "var(--hairline)"
        },
        ghost: {
          bg:        "transparent",
          border:    "var(--hairline)",
          shadow:    nil,
          eyebrow:   "var(--text-muted)",
          title:     "var(--text-muted)",
          chevron:   "var(--text-muted)",
          icon_bg:   nil,
          icon_brd:  nil
        }
      }.freeze

      def initialize(title:, url: nil, eyebrow: nil, tint: :neutral, icon: nil, emoji: nil, chevron: true, test_id: nil, **options)
        @title    = title
        @url      = url
        @eyebrow  = eyebrow
        @tint     = TINTS[tint.to_sym] || TINTS[:neutral]
        @ghost    = tint.to_sym == :ghost
        @icon     = icon
        @emoji    = emoji
        @chevron  = chevron
        @test_id  = test_id
        @options  = options
        super()
      end

      attr_reader :title, :url, :eyebrow, :tint, :icon, :emoji, :chevron, :test_id, :ghost

      def container_tag
        url.present? ? :a : :div
      end

      def container_attrs
        attrs = {
          class: "ls-card-3d block no-underline w-full",
          data:  { testid: test_id }.compact
        }
        attrs[:href] = url if url.present?
        attrs
      end

      def container_style
        s = ["display: block", "color: inherit", "text-decoration: none",
             "background: #{tint[:bg]}",
             "border-radius: 14px",
             "padding: 12px 14px"]
        s << (ghost ? "border: 2px dashed #{tint[:border]}" : "border: 2px solid #{tint[:border]}")
        s << "box-shadow: 0 4px 0 #{tint[:shadow]}" if tint[:shadow]
        s.join("; ")
      end

      def icon_cell_style
        return nil if tint[:icon_bg].nil?
        "background: #{tint[:icon_bg]}; border: 2px solid #{tint[:icon_brd]};"
      end
    end
  end
end
