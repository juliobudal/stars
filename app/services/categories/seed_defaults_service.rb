module Categories
  class SeedDefaultsService < ApplicationService
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

    def call
      return ok if @family.categories.exists?

      ActiveRecord::Base.transaction do
        DEFAULTS.each_with_index do |attrs, index|
          @family.categories.create!(attrs.merge(position: index))
        end
      end

      ok
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Categories::SeedDefaultsService] failed family_id=#{@family&.id} error=#{e.message}")
      fail_with(e.message)
    end
  end
end
