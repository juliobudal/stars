# frozen_string_literal: true

module Ui
  module FormErrors
    # Rose/danger-tinted panel listing ActiveRecord validation errors.
    # Renders nothing when the record has no errors, so callers can use
    # `<%= render Ui::FormErrors::Component.new(record: @model) %>` at
    # the top of every form unconditionally.
    #
    # Replaces the duplicated error block in categories/_form,
    # rewards/_form, global_tasks/_form, profiles/_form. See
    # .planning/ui-reviews/20260428-audit/03-parent-surfaces.md §7.
    class Component < ApplicationComponent
      def initialize(record:, title: "Ops! Algo deu errado", **options)
        @record = record
        @title = title
        @options = options
        super()
      end

      def render?
        @record.respond_to?(:errors) && @record.errors.any?
      end

      def messages
        @record.errors.full_messages
      end
    end
  end
end
