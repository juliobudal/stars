module Ui
  module SmileyAvatar
    class Component < ApplicationComponent
      COLOR_MAP = {
        "lila"    => { fill: "#EDE9FE", ring: "#C4B5FD", ink: "#6D28D9" },
        "lilac"   => { fill: "#EDE9FE", ring: "#C4B5FD", ink: "#6D28D9" },
        "theo"    => { fill: "#CFFAFE", ring: "#67E8F9", ink: "#0E7490" },
        "zoe"     => { fill: "#FCE7F3", ring: "#F472B6", ink: "#BE185D" },
        "mom"     => { fill: "#FCE7F3", ring: "#F9A8D4", ink: "#BE185D" },
        "dad"     => { fill: "#DBEAFE", ring: "#93C5FD", ink: "#1D4ED8" },
        "primary" => { fill: "#EDE9FE", ring: "#C4B5FD", ink: "#6D28D9" },
        "mint"    => { fill: "#D1FAE5", ring: "#6EE7B7", ink: "#047857" },
        "sky"     => { fill: "#E0F2FE", ring: "#7DD3FC", ink: "#0369A1" },
        "peach"   => { fill: "#FCE7F3", ring: "#F9A8D4", ink: "#BE185D" },
        "rose"    => { fill: "#FCE7F3", ring: "#F472B6", ink: "#BE185D" },
        "coral"   => { fill: "#FCE7F3", ring: "#F9A8D4", ink: "#BE185D" }
      }.freeze

      FACE_BY_COLOR = {
        "lila" => "wink", "lilac" => "wink",
        "zoe" => "tongue",
        "theo" => "smile",
        "mint" => "smile", "sky" => "smile",
        "peach" => "smile", "rose" => "smile", "coral" => "smile",
        "primary" => "smile"
      }.freeze

      def initialize(kid: nil, face: nil, size: 84, fill: nil, ring: nil, ink: nil, **options)
        @kid = kid
        @size = size
        @face = (face || derive_face(kid)).to_s
        palette = color_data(kid)
        @fill = fill || palette[:fill]
        @ring = ring || palette[:ring]
        @ink  = ink  || palette[:ink]
        @options = options
      end

      attr_reader :size, :face, :fill, :ring, :ink

      private

      def derive_face(kid)
        return "adult" if kid.respond_to?(:parent?) && kid.parent?
        return kid.face if kid.respond_to?(:face) && kid.face.present?
        key = kid&.respond_to?(:color) ? kid.color.to_s : ""
        FACE_BY_COLOR[key] || "smile"
      end

      def color_data(kid)
        key = kid.respond_to?(:color) ? kid.color.to_s.presence : nil
        COLOR_MAP[key] || COLOR_MAP["primary"]
      end
    end
  end
end
