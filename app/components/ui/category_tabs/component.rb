# frozen_string_literal: true

module Ui
  module CategoryTabs
    class Component < ApplicationComponent
      def initialize(items:, active:, controller: "tabs")
        @items = items
        @active = active.to_s
        @controller = controller
        super()
      end

      attr_reader :items, :active, :controller

      def active?(id)
        id.to_s == active
      end
    end
  end
end
