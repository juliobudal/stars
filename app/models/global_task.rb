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
#  featured                   :boolean          default(FALSE), not null
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
#  index_global_tasks_on_family_id               (family_id)
#  index_global_tasks_on_family_id_and_featured  (family_id,featured) WHERE (featured = true)
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

  scope :for_family, ->(family_id) { where(family_id: family_id) }
  scope :with_assignments, -> { includes(:assigned_profiles) }
  scope :by_priority, -> { order(active: :desc, title: :asc) }

  enum :category, { escola: 0, casa: 1, rotina: 2, saude: 3, outro: 4 }
  enum :frequency, { daily: 0, weekly: 1, monthly: 2, once: 3 }

  validates :title, presence: true
  validates :frequency, presence: true
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

  validate :assigned_profiles_must_belong_to_family

  after_update_commit :refresh_slots_after_cap_change, if: :saved_change_to_max_completions_per_period?

  def repeatable?
    max_completions_per_period.to_i > 1
  end

  # A task with zero explicit assignments is implicitly assigned to ALL
  # children in the family (see Tasks::DailyResetService#materialize_today).
  # Reads through `assigned_profiles` so a preloaded association is reused
  # (the host models run strict_loading in development).
  def assigned_to_all?
    assigned_profiles.empty?
  end

  # Whether this task's schedule fires on the given date. Pure calendar check —
  # ignores the `active` flag and per-profile "once" dedup. Prefer
  # `materialize_slot_for` as the single authority that bundles the dedup;
  # only call this directly when you genuinely want the schedule-only answer.
  def applicable_on?(date)
    case frequency.to_s
    when "daily"   then true
    when "weekly"  then days_of_week.present? && days_of_week.map(&:to_i).include?(date.wday)
    when "monthly" then day_of_month == date.day
    when "once"    then true
    else false
    end
  end

  # A `once` task is materialized at most one slot per profile, ever.
  # Direct query (not association traversal) so a strict_loading GlobalTask
  # doesn't raise in development.
  def once_completed_for?(profile)
    once? && ProfileTask.where(global_task_id: id, profile_id: profile.id).exists?
  end

  # Single authority for "should this child get today's slot now?". Honors the
  # `once` dedup so DailyResetService and Tasks::SetAssignments can't drift.
  # Returns the SlotRefresher result, or nil when skipped.
  def materialize_slot_for(profile, date)
    return if once_completed_for?(profile)

    Tasks::SlotRefresher.new(profile: profile, global_task: self, date: date).call
  end

  private

  def force_single_completion_for_once
    self.max_completions_per_period = 1 if once?
  end

  def refresh_slots_after_cap_change
    target_profiles = assigned_profiles.any? ? assigned_profiles.select(&:child?) : family.profiles.select(&:child?)
    target_profiles.each do |child|
      Tasks::SlotRefresher.new(profile: child, global_task: self).call
    end
  rescue StandardError => e
    Rails.logger.warn("[GlobalTask] refresh_slots_after_cap_change failed id=#{id} error=#{e.message}")
  end

  def assigned_profiles_must_belong_to_family
    return if family_id.blank?
    requested = assigned_profile_ids.map(&:to_i).reject(&:zero?).uniq
    return if requested.empty?

    valid_count = Profile.where(id: requested, family_id: family_id).count
    return if valid_count == requested.length

    errors.add(:assigned_profile_ids, "incluem perfis de outra família")
  end
end
