# frozen_string_literal: true

module Ui
  module MissionListRow
    class Component < ApplicationComponent
      def initialize(mission:, assigned_profiles: [])
        @mission = mission
        @assigned_profiles = assigned_profiles.to_a
        super()
      end

      attr_reader :mission, :assigned_profiles

      def dom_id
        "mission_row_#{mission.id}"
      end

      def category_meta
        Ui::Tokens.category_for(mission.category)
      end

      def frequency_meta
        Ui::Tokens.frequency_for(mission.frequency)
      end

      def panel_keys
        keys = [ "all", mission.frequency.to_s ]
        keys << "inactive" unless mission.active?
        keys.join(" ")
      end
    end
  end
end
