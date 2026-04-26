# frozen_string_literal: true

module Ui
  module ApprovalRow
    class Component < ApplicationComponent
      def initialize(kid:, title:, meta:, points:, approve_url:, reject_url:,
                     dom_id: nil, kid_chip_text: nil, category_label: nil,
                     points_sign: "+", approve_label: "Aprovar", reject_label: "Rejeitar",
                     reject_confirm: nil, approve_submits_with: "Aprovando...",
                     reject_submits_with: "Rejeitando...", bulk: false, bulk_value: nil,
                     profile_task: nil, compact: false, category: nil,
                     submission_comment: nil, custom: false, points_editable: false)
        @bulk = bulk
        @bulk_value = bulk_value
        @kid = kid
        @title = title
        @meta = meta
        @points = points
        @approve_url = approve_url
        @reject_url = reject_url
        @dom_id = dom_id
        @kid_chip_text = kid_chip_text || kid&.name
        @category_label = category_label
        @points_sign = points_sign
        @points_color = points_sign == "-" ? "var(--danger)" : "var(--star-2)"
        @approve_label = approve_label
        @reject_label = reject_label
        @reject_confirm = reject_confirm
        @approve_submits_with = approve_submits_with
        @reject_submits_with = reject_submits_with
        @profile_task = profile_task
        @compact = compact
        @category = category || profile_task&.try(:category) || profile_task&.global_task&.try(:category)
        @submission_comment = submission_comment
        @custom = custom
        @points_editable = points_editable
        super()
      end

      attr_reader :kid, :title, :meta, :points, :approve_url, :reject_url,
                  :dom_id, :kid_chip_text, :category_label, :points_sign,
                  :points_color, :approve_label, :reject_label, :reject_confirm,
                  :approve_submits_with, :reject_submits_with, :bulk, :bulk_value,
                  :profile_task, :compact, :category,
                  :submission_comment, :custom, :points_editable

      def category_meta
        return nil if category.blank?
        Ui::Tokens.category_for(category.to_s)
      end

      def bulk?
        @bulk
      end

      def compact?
        @compact
      end

      def palette
        @palette ||= Ui::SmileyAvatar::Component::COLOR_MAP[kid&.color.to_s] ||
                     Ui::SmileyAvatar::Component::COLOR_MAP["primary"]
      end
    end
  end
end
