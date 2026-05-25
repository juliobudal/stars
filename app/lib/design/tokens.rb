module Design
  # Server-side mirror of CSS variables defined in
  # app/assets/stylesheets/tailwind/theme.css. Use these constants from any
  # context that cannot read CSS variables (SVG views, PWA manifest, mailers,
  # PDF generation). The CSS theme is the source of truth — if values diverge,
  # this file is out of date.
  module Tokens
    PRIMARY      = "#58CC02".freeze
    PRIMARY_2    = "#46A302".freeze
    STAR         = "#FFC800".freeze
    DANGER       = "#FF4B4B".freeze
    INFO         = "#1CB0F6".freeze
    SURFACE      = "#FFFFFF".freeze
    BG_DEEP      = "#F7F7F7".freeze
    TEXT         = "#1C1C1E".freeze
    TEXT_MUTED   = "#4A4A4F".freeze
    TEXT_SUBTLE  = "#6A6A72".freeze
  end
end
