module Ui
  module ProfileCard
    class Component < ApplicationComponent
      def initialize(profile:, url:)
        @profile = profile
        @url = url
      end

      def palette
        Ui::SmileyAvatar::Component.palette_vars(@profile.color)
      end

      def initial
        @profile.name.first.upcase
      end

      def chip_class
        @profile.child? ? "chip-lilac" : "chip-#{@profile.color}"
      end

      def chip_variant
        @profile.child? ? "lilac" : (@profile.color.presence || "primary")
      end

      def chip_label
        @profile.child? ? "CRIANÇA" : "RESPONSÁVEL"
      end

      def points_text
        @profile.points.to_s if @profile.child?
      end
    end
  end
end
