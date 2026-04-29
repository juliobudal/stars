# == Schema Information
#
# Table name: global_tasks
#
#  id                         :bigint           not null, primary key
#  active                     :boolean          default(TRUE), not null
#  category                   :integer
#  day_of_month               :integer
#  days_of_week               :string           default([]), is an Array
#  description                :text
#  frequency                  :integer
#  icon                       :string
#  max_completions_per_period :integer          default(1), not null
#  points                     :integer
#  title                      :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  family_id                  :bigint           not null
#
# Indexes
#
#  index_global_tasks_on_family_id  (family_id)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#
class GlobalTask < ApplicationRecord
  belongs_to :family
  has_many :profile_tasks, dependent: :destroy
  has_many :global_task_assignments, dependent: :destroy
  has_many :assigned_profiles, through: :global_task_assignments, source: :profile

  enum :category, { escola: 0, casa: 1, rotina: 2, saude: 3, outro: 4 }
  enum :frequency, { daily: 0, weekly: 1, monthly: 2, once: 3 }

  validates :title, presence: true
  validates :points, numericality: { greater_than: 0 }
  validates :day_of_month, presence: true, if: :monthly?
  validates :day_of_month, numericality: { only_integer: true, in: 1..31 }, allow_nil: true, if: :monthly?

  MAX_COMPLETIONS_RANGE = (1..20).freeze

  before_validation :force_single_completion_for_once

  validates :max_completions_per_period,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: MAX_COMPLETIONS_RANGE.min,
              less_than_or_equal_to: MAX_COMPLETIONS_RANGE.max
            }

  def repeatable?
    max_completions_per_period.to_i > 1
  end

  private

  def force_single_completion_for_once
    self.max_completions_per_period = 1 if once?
  end
end
