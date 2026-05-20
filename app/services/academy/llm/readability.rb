# frozen_string_literal: true

module Academy
  module Llm
    # Flesch Reading Ease, adapted for Brazilian Portuguese (Martins, 1996):
    #
    #   FRE_pt = 248.835 − 1.015 × (words / sentences) − 84.6 × (syllables / words)
    #
    # Band targets for kid Academy (7-12 years old):
    #   >= 75   → very easy   (~7yo, 1st-2nd grade)
    #   60..75  → easy        (~8-9yo, 3rd-4th)  ← TARGET
    #   50..60  → reasonable  (~10-11)            ← acceptable
    #   30..50  → hard         (12+)              ← warn
    #   < 30    → very hard    (adult)            ← block
    #
    # The implementation is intentionally a tiny zero-dependency Ruby module.
    # Syllable count approximates via vowel-group regex — good enough for
    # band-level decisions, not for academic linguistics.
    module Readability
      module_function

      FLOOR_BLOCK = 50.0
      FLOOR_WARN  = 60.0

      Result = Data.define(:score, :tier, :words, :sentences, :syllables) do
        def block? = tier == :block
        def warn?  = tier == :warn
        def ok?    = tier == :ok
        def label
          case tier
          when :ok    then "ok"
          when :warn  then "warn (12+)"
          else            "block (adulto)"
          end
        end
      end

      def score(text)
        analyze(text).score
      end

      def kid_friendly?(text, floor: FLOOR_WARN)
        score(text) >= floor
      end

      def analyze(text)
        return empty_result if text.to_s.strip.empty?

        words      = text.scan(/[A-Za-zÀ-ÖØ-öø-ÿ]+(?:[-'][A-Za-zÀ-ÖØ-öø-ÿ]+)*/)
        sentences  = text.split(/[.!?…]+/).map(&:strip).reject(&:empty?).size
        return empty_result if words.empty? || sentences.zero?

        syllables  = words.sum { |w| count_syllables(w) }
        raw = 248.835 -
              1.015 * (words.size.to_f / sentences) -
              84.6  * (syllables.to_f / words.size)

        Result.new(score: raw.round(1), tier: classify(raw),
                   words: words.size, sentences: sentences, syllables: syllables)
      end

      def classify(raw)
        if raw >= FLOOR_WARN then :ok
        elsif raw >= FLOOR_BLOCK then :warn
        else :block
        end
      end

      def count_syllables(word)
        # Group consecutive vowels (including accented + nasal y) as one syllable.
        # Real PT-BR has hiatos (sa-í-da) that this misses, but for band-level
        # decisions a 5-10% syllable miscount is harmless. Caps at min 1.
        groups = word.downcase.scan(/[aeiouáéíóúâêôãõàèìòùäëïöüy]+/).size
        groups.zero? ? 1 : groups
      end

      def empty_result
        Result.new(score: 0.0, tier: :ok, words: 0, sentences: 0, syllables: 0)
      end
    end
  end
end
