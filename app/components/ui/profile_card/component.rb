module Ui
  module ProfileCard
    class Component < ApplicationComponent
      PALETTE = Ui::SmileyAvatar::Component::COLOR_MAP

      def initialize(profile:, url:)
        @profile = profile
        @url = url
      end

      def palette
        PALETTE[@profile.color.to_s] || PALETTE["primary"]
      end

      def initial
        @profile.name.first.upcase
      end

      def chip_class
        @profile.child? ? "chip-lilac" : "chip-#{@profile.color}"
      end

      def chip_label
        @profile.child? ? "CRIANÇA" : "RESPONSÁVEL"
      end

      def subtitle
        @profile.child? ? "#{@profile.points} ★" : nil
      end
    end
  end
end
