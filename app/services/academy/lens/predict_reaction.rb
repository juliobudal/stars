# frozen_string_literal: true

module Academy
  module Lens
    # Computes an age-appropriate reaction to a kid's predict-lens guess by
    # measuring the miss against the slider range, then optionally annotating
    # it with the magnitude (e.g. "2× a mais", "500× a menos").
    #
    # Bands (delta as % of range):
    #   0–2 %    → bullseye
    #   2–5 %    → close
    #   5–20 %   → off
    #   20–50 %  → way_off
    #   >50 %    → astronomical
    #
    # The JS mirror lives in `app/assets/controllers/lens_stage_controller.js`
    # (`_computePredictReaction`). Keep the band thresholds in sync.
    class PredictReaction
      Reaction = Data.define(:tier, :emoji, :headline, :detail)

      TIERS = %i[bullseye close off way_off astronomical].freeze

      def self.call(...) = new(...).call

      def initialize(guess:, real:, range_min: 0, range_max: 100)
        @guess = guess.to_f
        @real = real.to_f
        @range_min = range_min.to_f
        @range_max = range_max.to_f
      end

      def call
        tier = compute_tier
        Reaction.new(tier:, **content_for(tier))
      end

      private

      def compute_tier
        return :bullseye if (@guess - @real).abs < 0.5

        case range_pct
        when 0.0..0.02 then :bullseye
        when ..0.05    then :close
        when ..0.20    then :off
        when ..0.50    then :way_off
        else :astronomical
        end
      end

      def range_pct
        range = (@range_max - @range_min).abs
        return 1.0 if range.zero?
        (@guess - @real).abs / range
      end

      def multiplier
        return nil if @real.abs < 0.0001 || @guess.abs < 0.0001
        m = @guess.abs / @real.abs
        m >= 1 ? m : 1.0 / m
      end

      def direction
        @guess > @real ? "a mais" : "a menos"
      end

      def content_for(tier)
        case tier
        when :bullseye      then bullseye_content
        when :close         then close_content
        when :off           then off_content
        when :way_off       then way_off_content
        when :astronomical  then astronomical_content
        end
      end

      def bullseye_content
        {
          emoji: "🎯",
          headline: "Cravou!",
          detail: "Você é mais calibrado que a maioria dos adultos nessa."
        }
      end

      def close_content
        {
          emoji: "👀",
          headline: "Quase no ponto.",
          detail: "Sua intuição tava afinada — esses números são difíceis de chutar."
        }
      end

      def off_content
        m = multiplier
        detail = if m && m >= 2
          "Errou por uns #{m.round}× #{direction}. Dá pra calibrar com prática."
        else
          "Errou por margem pequena. Dá pra calibrar com prática."
        end
        { emoji: "🤏", headline: "Foi por pouco.", detail: detail }
      end

      def way_off_content
        m = multiplier
        detail = if m
          "Você apostou cerca de #{m.round}× #{direction} do real. Esse erro é exatamente o que essa lente revela."
        else
          "Errou por margem larga. Esse erro é exatamente o que essa lente revela."
        end
        { emoji: "😅", headline: "Errou pela ordem de grandeza.", detail: detail }
      end

      def astronomical_content
        m = multiplier
        detail = if m
          "Você apostou #{m.round}× #{direction} do real. O mundo é mais raro (ou mais comum) do que parece."
        else
          "A intuição te traiu feio aqui — o mundo nem sempre se comporta como a gente imagina."
        end
        { emoji: "🤯", headline: "Pirou!", detail: detail }
      end
    end
  end
end
