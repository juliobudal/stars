# frozen_string_literal: true

module Ui
  module FilterChips
    class Component < ApplicationComponent
      def initialize(items:, active:, controller: "tabs", label: nil)
        @items = items
        @active = active.to_s
        @controller = controller
        @label = label
        super()
      end

      attr_reader :items, :active, :controller, :label

      def active?(id)
        id.to_s == active
      end

      # ARIA role follows the controller's behavior, not the visual styling:
      #   "tabs"        switches between sibling #panel-* regions  -> tablist/tab/tabpanel
      #   "filter-tabs" shows/hides sibling cards in place         -> group of toggle buttons
      # Declaring role="tab" on a filter promises a tabpanel that never exists, so the
      # two modes emit different roles/state attributes (aria-selected vs aria-pressed).
      def filter_mode?
        controller == "filter-tabs"
      end

      def container_role
        filter_mode? ? "group" : "tablist"
      end

      def container_label
        filter_mode? ? (label.presence || "Filtros") : label.presence
      end
    end
  end
end
