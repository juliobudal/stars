# frozen_string_literal: true

module Academy
  module Illustrations
    # Wraps a curated `illustration_hint` with a fixed Duolingo-style prefix
    # so every generated image shares the same visual contract — flat vector,
    # vibrant Duolingo green, no text, square composition, friendly mood.
    #
    # PREFIX is the visual contract. Bumping it MUST bump STYLE_VERSION too;
    # the generation pipeline compares stored meta.style against this constant
    # to decide whether previously-generated images are stale.
    module PromptComposer
      STYLE_VERSION = "duolingo@v2"

      PREFIX = <<~PROMPT.strip.freeze
        Flat vector illustration in the style of a wordless children's
        picture book. Communication is purely visual — symbols, icons,
        gestures, and facial expressions only. All surfaces (signs, screens,
        papers, walls, thought bubbles) are intentionally blank or contain
        only simple pictograms.

        Duolingo aesthetic: rounded geometric shapes, vibrant Duolingo green
        (#58CC02) as the primary accent over a soft pastel palette of peach,
        sky blue, and butter yellow. Thick clean outlines, friendly mascot
        energy, cheerful and curious mood. White background, square 1:1
        composition, child-friendly tone.

        Final check: every sign, page, screen, and bubble in this image is
        intentionally blank or shows only a simple pictogram — no letters,
        no numbers, no words anywhere.
      PROMPT

      module_function

      def compose(hint:)
        "#{PREFIX}\n\nScene: #{hint}"
      end
    end
  end
end
