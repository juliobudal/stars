# frozen_string_literal: true

module Ui
  module Tokens
    MISSION_CATEGORIES = {
      "casa"   => { label: "Casa",   icon: "home",    tint: "mint"  },
      "escola" => { label: "Escola", icon: "book",    tint: "lilac" },
      "rotina" => { label: "Rotina", icon: "brush",   tint: "rose"  },
      "saude"  => { label: "Saúde",  icon: "muscle",  tint: "star"  },
      "geral"  => { label: "Geral",  icon: "sparkle", tint: "sky"   },
      "outro"  => { label: "Outro",  icon: "sparkle", tint: "sky"   }
    }.freeze

    FREQUENCIES = {
      "daily"  => { label: "Todo dia", tint: "mint" },
      "weekly" => { label: "Semanal",  tint: "sky"  }
    }.freeze

    def self.category_for(key)
      MISSION_CATEGORIES.fetch(key.to_s, MISSION_CATEGORIES["geral"])
    end

    def self.frequency_for(key)
      FREQUENCIES.fetch(key.to_s, FREQUENCIES["daily"])
    end

    def self.tint_soft(name)
      name.to_s == "primary" ? "var(--primary-soft)" : "var(--c-#{name}-soft)"
    end

    def self.tint_fg(name)
      name.to_s == "primary" ? "var(--primary)" : "var(--c-#{name})"
    end
  end
end
