require "ostruct"

module Categories
  class SeedDefaultsService
    DEFAULTS = [
      { name: "Telinha",      icon: "game-controller-01", color: "sky"   },
      { name: "Docinhos",     icon: "ice-cream-01",       color: "rose"  },
      { name: "Passeios",     icon: "ferris-wheel",       color: "mint"  },
      { name: "Brinquedos",   icon: "cube",               color: "amber" },
      { name: "Experiências", icon: "gift",               color: "lilac" },
      { name: "Outro",        icon: "bookmark-01",        color: "peach" }
    ].freeze

    def initialize(family)
      @family = family
    end

    def self.call(family)
      new(family).call
    end

    def call
      return OpenStruct.new(success?: true, error: nil) if @family.categories.exists?

      ActiveRecord::Base.transaction do
        DEFAULTS.each_with_index do |attrs, index|
          @family.categories.create!(attrs.merge(position: index))
        end
      end

      OpenStruct.new(success?: true, error: nil)
    end
  end
end
