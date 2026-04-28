# frozen_string_literal: true

module Ui
  module FormSection
    # White-card form section with hairline border, card shadow, and
    # 16px radius. Replaces the inline
    #   `bg-surface rounded-[16px] border-2 border-hairline p-[18px]`
    # block duplicated 14+ times across parent form partials. See
    # .planning/ui-reviews/20260428-audit/03-parent-surfaces.md §7.
    #
    # API:
    #   render Ui::FormSection::Component.new(title: "Nome da categoria") do
    #     # form fields…
    #   end
    #
    # `title` (when present) renders an uppercase eyebrow header inside
    # the card. Pass nil/omit for an unlabeled section.
    class Component < ApplicationComponent
      def initialize(title: nil, **options)
        @title = title
        @options = options
        super()
      end
    end
  end
end
