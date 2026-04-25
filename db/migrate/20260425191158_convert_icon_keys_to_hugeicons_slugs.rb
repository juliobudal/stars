class ConvertIconKeysToHugeiconsSlugs < ActiveRecord::Migration[8.1]
  ALIASES = {
    "bed" => "bed-single-01", "brush" => "dental-care", "book" => "book-01",
    "dish" => "dish-01", "bookOpen" => "book-open-01", "bear" => "bone-01",
    "paw" => "bone-02", "music" => "music-note-01", "sun" => "sun-01",
    "home" => "home-01", "graduationCap" => "mortarboard-01", "muscle" => "dumbbell-01",
    "iceCream" => "ice-cream-01", "gamepad" => "game-controller-01",
    "ferris" => "ferris-wheel", "blocks" => "cube", "pizza" => "pizza-01",
    "film" => "film-01", "moon" => "moon-01", "bookSolid" => "bookmark-01",
    "gift" => "gift", "heart" => "favourite", "target" => "target-01",
    "star" => "star"
  }.freeze

  def up
    [ GlobalTask, Reward ].each do |klass|
      klass.reset_column_information
      klass.where.not(icon: [ nil, "" ]).find_each do |row|
        next if row.icon.include?("-") # already raw
        slug = ALIASES[row.icon]
        next unless slug
        klass.where(id: row.id).update_all(icon: slug)
      end
    end
  end

  def down
    # no-op — alias inversion is lossy
  end
end
