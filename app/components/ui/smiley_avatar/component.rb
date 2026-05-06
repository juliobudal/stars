module Ui
  module SmileyAvatar
    class Component < ApplicationComponent
      # Whitelist of palette names. Colors are defined as CSS tokens
      # in app/assets/stylesheets/tailwind/theme.css and resolved by
      # component.css via [data-avatar-palette="<name>"].
      PALETTES = %w[lilac theo zoe mom dad primary mint sky peach rose coral].freeze

      FACE_BY_COLOR = {
        "lilac" => "wink",
        "zoe" => "tongue",
        "theo" => "smile",
        "mint" => "smile", "sky" => "smile",
        "peach" => "smile", "rose" => "smile", "coral" => "smile",
        "primary" => "smile"
      }.freeze

      # Returns the per-kid color hash with var() references that resolve
      # to the --avatar-<name>-{fill,tile,ring,ink} tokens in theme.css.
      # Use this for inline-style interpolation; prefer the
      # data-avatar-palette attribute when CSS can carry the token.
      def self.palette_vars(color_key)
        key = color_key.to_s
        key = "lilac" if key == "lila"
        key = "primary" unless PALETTES.include?(key)
        {
          fill: "var(--avatar-#{key}-fill)",
          tile: "var(--avatar-#{key}-tile)",
          ring: "var(--avatar-#{key}-ring)",
          ink:  "var(--avatar-#{key}-ink)"
        }
      end

      def initialize(kid: nil, face: nil, size: 84, **options)
        @kid = kid
        @size = size
        @face = (face || derive_face(kid)).to_s
        @options = options
      end

      attr_reader :size, :face

      def palette
        key = @kid.respond_to?(:color) ? @kid.color.to_s.presence : nil
        # Alias legacy `lila` → canonical `lilac`.
        key = "lilac" if key == "lila"
        PALETTES.include?(key) ? key : "primary"
      end

      def avatar_slug
        explicit = @kid.respond_to?(:avatar) ? @kid.avatar.presence : nil
        explicit || default_slug
      end

      def default_slug
        return "user-circle" if @kid.respond_to?(:parent?) && @kid.parent?
        "happy-01"
      end

      private

      def derive_face(kid)
        return "adult" if kid.respond_to?(:parent?) && kid.parent?
        return kid.face if kid.respond_to?(:face) && kid.face.present?
        key = kid&.respond_to?(:color) ? kid.color.to_s : ""
        key = "lilac" if key == "lila"
        FACE_BY_COLOR[key] || "smile"
      end
    end
  end
end
