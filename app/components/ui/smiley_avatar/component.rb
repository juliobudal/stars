module Ui
  module SmileyAvatar
    class Component < ApplicationComponent
      # Whitelist of palette names. Colors are defined as CSS tokens
      # in app/assets/stylesheets/tailwind/theme.css and resolved by
      # component.css via [data-avatar-palette="<name>"].
      PALETTES = %w[lilac theo zoe mom dad primary mint sky peach rose coral].freeze

      # Back-compat shim: external callers (approval_row, kid_initial_chip,
      # kid_progress_card, profile_card, parent/global_tasks/_form) still
      # read raw hex from this constant for inline-style interpolation.
      # When those callers are migrated to data-avatar-palette, this
      # constant can be removed. Note: no `lila` key — `lilac` is canonical.
      COLOR_MAP = {
        "lilac"   => { fill: "#EDE9FE", tile: "#F8F5FF", ring: "#C4B5FD", ink: "#6D28D9" },
        "theo"    => { fill: "#CFFAFE", tile: "#F0FDFF", ring: "#67E8F9", ink: "#0E7490" },
        "zoe"     => { fill: "#FCE7F3", tile: "#FFF0F6", ring: "#F472B6", ink: "#BE185D" },
        "mom"     => { fill: "#FCE7F3", tile: "#FFF0F6", ring: "#F9A8D4", ink: "#BE185D" },
        "dad"     => { fill: "#DBEAFE", tile: "#EFF6FF", ring: "#93C5FD", ink: "#1D4ED8" },
        "primary" => { fill: "#EDE9FE", tile: "#F8F5FF", ring: "#C4B5FD", ink: "#6D28D9" },
        "mint"    => { fill: "#D1FAE5", tile: "#ECFDF5", ring: "#6EE7B7", ink: "#047857" },
        "sky"     => { fill: "#E0F2FE", tile: "#F0F9FF", ring: "#7DD3FC", ink: "#0369A1" },
        "peach"   => { fill: "#FCE7F3", tile: "#FFF0F6", ring: "#F9A8D4", ink: "#BE185D" },
        "rose"    => { fill: "#FCE7F3", tile: "#FFF0F6", ring: "#F472B6", ink: "#BE185D" },
        "coral"   => { fill: "#FCE7F3", tile: "#FFF0F6", ring: "#F9A8D4", ink: "#BE185D" }
      }.freeze

      FACE_BY_COLOR = {
        "lilac" => "wink",
        "zoe" => "tongue",
        "theo" => "smile",
        "mint" => "smile", "sky" => "smile",
        "peach" => "smile", "rose" => "smile", "coral" => "smile",
        "primary" => "smile"
      }.freeze

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
