# frozen_string_literal: true

# Renders the Pokédex orb for a single concept on the Atlas screen.
#
# Visual contract (DESIGN.md + .planning/designs/academy-v4-tasks.md, audit PR3):
#   L0 silhouette  → grayscale, low brightness
#   L1 spotted     → tinted with --academy-pokedex-{color_key}, 0.6 opacity
#   L2 recognized  → full color
#   L3 mastered    → full color + glow ring + pulse animation (honors reduced-motion via CSS)
#
# Falls back to the category glyph (_{color_key}.svg) when the concept
# has no dedicated silhouette asset.
module Kid
  module Academy
    module Atlas
      class ConceptOrbComponent < ApplicationComponent
        ASSET_ROOT = Rails.root.join("app/assets/images/academy/pokedex").freeze
        DEFAULT_COLOR_KEY = "cognitivo"

        def initialize(concept:, level:, size: 40)
          @concept = concept
          @level = level.to_i.clamp(0, 3)
          @size = size
          super()
        end

        def call
          content_tag :span,
            inline_svg.html_safe, # rubocop:disable Rails/OutputSafety
            class: "pokedex-orb #{state_class}",
            style: container_style,
            "data-concept-slug": @concept.slug,
            "data-level": @level,
            "aria-hidden": true
        end

        private

        def state_class
          case @level
          when 3 then "pokedex-orb--mastered"
          when 2 then "pokedex-orb--recognized"
          when 1 then "pokedex-orb--spotted"
          else        "pokedex-orb--silhouette"
          end
        end

        def container_style
          color_var = "var(--academy-pokedex-#{color_key})"
          "width: #{@size}px; height: #{@size}px; color: #{color_var}; --pokedex-orb-color: #{color_var};"
        end

        def color_key
          @concept.pokedex_color_key.presence || DEFAULT_COLOR_KEY
        end

        def inline_svg
          self.class.svg_for(asset_filename)
        end

        def asset_filename
          if @concept.pokedex_silhouette_key.present?
            candidate = "#{@concept.pokedex_silhouette_key}.svg"
            return candidate if self.class.asset_exists?(candidate)
          end
          "_#{color_key}.svg"
        end

        class << self
          def svg_for(filename)
            cache[filename] ||= load_svg(filename)
          end

          def asset_exists?(filename)
            ASSET_ROOT.join(filename).file?
          end

          private

          def cache
            @cache ||= {}
          end

          def load_svg(filename)
            path = ASSET_ROOT.join(filename)
            path = ASSET_ROOT.join("_#{DEFAULT_COLOR_KEY}.svg") unless path.file?
            path.read
          end
        end
      end
    end
  end
end
