class Ui::Icon::Component < ApplicationComponent
  PHOSPHOR_MAP = {
    # core / ui
    star: "star",
    starOutline: "star", # rendered with weight="regular"
    check: "check",
    close: "x",
    back: "arrow-left",
    plus: "plus",
    edit: "pencil-simple",
    trash: "trash",
    logout: "sign-out",
    chevron: "caret-right",
    sparkle: "sparkle",
    heart: "heart",
    gift: "gift",
    clock: "clock",
    trending: "trending-up",
    arrowUp: "arrow-up",
    arrowDown: "arrow-down",
    sword: "sword",

    # nav
    target: "target",
    bag: "shopping-bag",
    scroll: "scroll",
    home: "house",
    users: "users-three",

    # missions
    bed: "bed",
    brush: "tooth",
    book: "book",
    dish: "bowl-food",
    bookOpen: "book-open",
    bear: "rabbit",
    paw: "paw-print",
    music: "guitar",
    sun: "sun",
    graduationCap: "graduation-cap",
    muscle: "barbell",

    # shop
    iceCream: "ice-cream",
    gamepad: "game-controller",
    ferris: "park",
    blocks: "lego",
    pizza: "pizza",
    film: "film-strip",
    moon: "moon",
    bookSolid: "book-bookmark",

    # avatars (all face-family for consistency)
    faceKid: "smiley",
    faceParent: "user-circle",
    faceFox: "smiley-wink",
    faceHero: "smiley-sticker",
    facePrincess: "smiley-melting"
  }.freeze

  def initialize(name = nil, size: 24, color: "currentColor", weight: "fill", **options)
    @name = name
    @size = size
    @color = color
    @weight = weight
    @options = options
  end

  def call
    name = @name.presence || content.to_s.presence || @options.delete(:name)
    glyph = PHOSPHOR_MAP[name.to_sym] || PHOSPHOR_MAP[name.to_s.to_sym] || name
    weight = (name.to_s == "starOutline") ? "regular" : @weight

    content_tag :i, nil,
      class: class_names("ph-#{weight}", "ph-#{glyph}", @options.delete(:class)),
      style: "font-size: #{@size}px; line-height: 1; color: #{@color}; display: inline-flex; align-items: center; justify-content: center; width: #{@size}px; height: #{@size}px; #{@options.delete(:style)}",
      "aria-hidden": true,
      **@options
  end
end
