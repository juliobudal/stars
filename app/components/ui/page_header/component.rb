# frozen_string_literal: true

module Ui
  module PageHeader
    # Shared parent-surface page header.
    #
    # Replaces 8 hand-rolled `<h1> + subtitle + CTA` flex blocks across
    # parent index pages (dashboard, approvals, categories, rewards,
    # profiles, global_tasks, activity_logs, settings). See
    # .planning/ui-reviews/20260428-audit/03-parent-surfaces.md §6.
    #
    # API:
    #   render Ui::PageHeader::Component.new(title:, subtitle:) do |h|
    #     h.with_left_action { link_to ... }   # optional, mutually exclusive with default lockup
    #     h.with_right_slot  { render Ui::Btn::... }
    #   end
    class Component < ApplicationComponent
      renders_one :right_slot
      renders_one :left_action

      def initialize(title:, subtitle: nil, **options)
        @title = title
        @subtitle = subtitle
        @options = options
        super()
      end
    end
  end
end
