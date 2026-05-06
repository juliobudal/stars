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
      "daily"   => { label: "Todo dia",  tint: "mint"  },
      "weekly"  => { label: "Semanal",   tint: "sky"   },
      "monthly" => { label: "Mensal",    tint: "lilac" },
      "once"    => { label: "Única vez", tint: "rose"  }
    }.freeze

    CATEGORY_COLOR_PALETTE = {
      "sky"    => { label: "Céu",     soft_var: "var(--c-sky-soft)",    fg_var: "var(--c-sky)"    },
      "rose"   => { label: "Rosa",    soft_var: "var(--c-rose-soft)",   fg_var: "var(--c-rose)"   },
      "mint"   => { label: "Menta",   soft_var: "var(--c-mint-soft)",   fg_var: "var(--c-mint)"   },
      "amber"  => { label: "Âmbar",   soft_var: "var(--c-amber-soft)",  fg_var: "var(--c-amber)"  },
      "lilac"  => { label: "Lilás",   soft_var: "var(--c-lilac-soft)",  fg_var: "var(--c-lilac)"  },
      "peach"  => { label: "Pêssego", soft_var: "var(--c-peach-soft)",  fg_var: "var(--c-peach)"  },
      "star"   => { label: "Dourado", soft_var: "var(--c-star-soft)",   fg_var: "var(--c-star)"   }
    }.freeze

    def self.category_for(key)
      MISSION_CATEGORIES.fetch(key.to_s, MISSION_CATEGORIES["geral"])
    end

    def self.frequency_for(key)
      FREQUENCIES.fetch(key.to_s, FREQUENCIES["daily"])
    end

    def self.color_palette_entry(key)
      CATEGORY_COLOR_PALETTE.fetch(key.to_s, CATEGORY_COLOR_PALETTE["lilac"])
    end

    def self.tint_soft(name)
      name.to_s == "primary" ? "var(--primary-soft)" : "var(--c-#{name}-soft)"
    end

    def self.tint_fg(name)
      name.to_s == "primary" ? "var(--primary)" : "var(--c-#{name})"
    end
  end
end
