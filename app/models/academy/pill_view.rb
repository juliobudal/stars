# frozen_string_literal: true

# == Schema Information
#
# Table name: academy_pill_views
#
#  id                  :bigint           not null, primary key
#  learner_id          :bigint           not null
#  lens_cache_id       :bigint           not null
#  status              :string           not null, default("served")
#  micro_check_choice  :integer
#  micro_check_correct :boolean
#  shared_with_parent  :boolean          not null, default(false)
#  viewed_at           :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
module Academy
  class PillView < ApplicationRecord
    self.table_name = "academy_pill_views"

    STATUSES = %w[served viewed checked shared].freeze
    validates :status, inclusion: { in: STATUSES }
    validates :learner_id, presence: true
    validates :lens_cache_id, presence: true,
              uniqueness: { scope: :learner_id }

    belongs_to :lens_cache, class_name: "Academy::LensCache"

    scope :for_learner, ->(learner_id) { where(learner_id: learner_id) }
    scope :recent,      -> { order(created_at: :desc) }
    scope :today,       -> { where(created_at: Time.current.beginning_of_day..) }

    def mark_viewed!
      return if viewed_at?

      update!(status: "viewed", viewed_at: Time.current)
    end

    def mark_shared!
      update!(status: "shared", shared_with_parent: true)
    end
  end
end
