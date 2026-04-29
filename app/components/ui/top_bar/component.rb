module Ui
  module TopBar
    class Component < ApplicationComponent
      renders_one :left_action
      renders_one :right_slot

      def initialize(title: nil, subtitle: nil, back_url: nil, title_id: nil, subtitle_id: nil, **options)
        @title = title
        @subtitle = subtitle
        @back_url = back_url
        @title_id = title_id
        @subtitle_id = subtitle_id
        @options = options
        super()
      end
    end
  end
end
