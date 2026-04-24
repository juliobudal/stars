class Ui::Icon::Component < ApplicationComponent
  HUGEICONS_MAP = {
    # core / ui
    star: "star",
    starOutline: "star",
    check: "tick-01",
    close: "cancel-01",
    back: "arrow-left-01",
    plus: "plus-sign",
    edit: "pencil-edit-02",
    trash: "delete-02",
    logout: "logout-01",
    chevron: "arrow-right-01",
    sparkle: "sparkles",
    heart: "favourite",
    gift: "gift",
    clock: "clock-01",
    trending: "chart-line-data-01",
    arrowUp: "arrow-up-01",
    arrowDown: "arrow-down-01",
    sword: "sword-01",

    # celebration / feedback
    party: "party",
    fireworks: "fireworks",
    fire: "fire",

    # nav
    target: "target-01",
    bag: "shopping-bag-01",
    scroll: "scroll",
    home: "home-01",
    users: "user-multiple",

    # missions
    bed: "bed-single-01",
    brush: "dental-care",
    book: "book-01",
    dish: "dish-01",
    bookOpen: "book-open-01",
    bear: "bone-01",
    paw: "bone-02",
    music: "music-note-01",
    sun: "sun-01",
    graduationCap: "mortarboard-01",
    muscle: "dumbbell-01",

    # shop
    iceCream: "ice-cream-01",
    gamepad: "game-controller-01",
    ferris: "ferris-wheel",
    blocks: "cube",
    pizza: "pizza-01",
    film: "film-01",
    moon: "moon-01",
    bookSolid: "bookmark-01",

    # avatars
    faceKid: "happy-01",
    faceParent: "user-circle",
    faceFox: "happy-01",
    faceHero: "award-01",
    facePrincess: "crown",

    # literal aliases (legacy names still used in views)
    "arrow-left": "arrow-left-01",
    "arrow-right": "arrow-right-01",
    pencil: "pencil-edit-02",
    bell: "notification-01",
    lock: "square-lock-01",
    "user-circle": "user-circle",
    wallet: "wallet-01"
  }.freeze

  STYLE_MAP = {
    "fill"    => "stroke",
    "solid"   => "stroke",
    "regular" => "stroke",
    "stroke"  => "stroke",
    "duotone" => "stroke",
    "bulk"    => "stroke",
    "twotone" => "stroke",
    "bold"    => "stroke"
  }.freeze

  def initialize(name = nil, size: 24, color: "currentColor", weight: "stroke", **options)
    @name = name
    @size = size
    @color = color
    @weight = weight
    @options = options
  end

  def call
    name = @name.presence || content.to_s.presence || @options.delete(:name)
    glyph = HUGEICONS_MAP[name.to_sym] || HUGEICONS_MAP[name.to_s.to_sym] || name
    weight = (name.to_s == "starOutline") ? "regular" : @weight
    style = STYLE_MAP[weight.to_s] || "stroke"

    content_tag :i, nil,
      class: class_names("hgi-#{style}", "hgi-#{glyph}", @options.delete(:class)),
      style: "font-size: #{@size}px; line-height: 1; color: #{@color}; display: inline-flex; align-items: center; justify-content: center; width: #{@size}px; height: #{@size}px; #{@options.delete(:style)}",
      "aria-hidden": true,
      **@options
  end
end
