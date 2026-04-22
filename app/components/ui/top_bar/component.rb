module Ui
  module TopBar
    class Component < ApplicationComponent
      renders_one :left_action
      renders_one :right_slot

      def initialize(title: nil, subtitle: nil, back_url: nil, **options)
        @title = title
        @subtitle = subtitle
        @back_url = back_url
        @options = options
        super()
      end
    end
  end
end
