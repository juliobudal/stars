# == Schema Information
#
# Table name: profile_tasks
#
#  id                 :bigint           not null, primary key
#  assigned_date      :date
#  completed_at       :datetime
#  custom_description :text
#  custom_points      :integer
#  custom_title       :string
#  source             :integer          default("catalog"), not null
#  status             :integer          default("pending")
#  submission_comment :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  custom_category_id :bigint
#  global_task_id     :bigint
#  profile_id         :bigint           not null
#
# Indexes
#
#  index_profile_tasks_on_custom_category_id            (custom_category_id)
#  index_profile_tasks_on_global_task_id                (global_task_id)
#  index_profile_tasks_on_profile_id                    (profile_id)
#  index_profile_tasks_on_profile_id_and_assigned_date  (profile_id,assigned_date)
#  index_profile_tasks_on_profile_id_and_status         (profile_id,status)
#  index_profile_tasks_on_source                        (source)
#
# Foreign Keys
#
#  fk_rails_...  (custom_category_id => categories.id) ON DELETE => nullify
#  fk_rails_...  (global_task_id => global_tasks.id)
#  fk_rails_...  (profile_id => profiles.id)
#
class ProfileTask < ApplicationRecord
  belongs_to :profile
  belongs_to :global_task, optional: true
  belongs_to :custom_category, class_name: "Category", optional: true

  has_one_attached :proof_photo

  enum :status, { pending: 0, awaiting_approval: 1, approved: 2, rejected: 3 }, default: :pending
  enum :source, { catalog: 0, custom: 1 }, default: :catalog

  PROOF_PHOTO_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  PROOF_PHOTO_MAX_SIZE = 5.megabytes
  CUSTOM_TITLE_MAX = 120
  CUSTOM_POINTS_RANGE = (1..1000).freeze
  ONCE_PERIOD_FLOOR = Date.new(2000, 1, 1).freeze

  validate :proof_photo_valid, if: -> { proof_photo.attached? }
  validate :catalog_requires_global_task, if: :catalog?
  validate :custom_rejects_global_task, if: :custom?
  validates :custom_title, presence: true, length: { maximum: CUSTOM_TITLE_MAX }, if: :custom?
  validates :custom_points,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: CUSTOM_POINTS_RANGE.min, less_than_or_equal_to: CUSTOM_POINTS_RANGE.max },
            if: :custom?
  validate :custom_requires_category, if: :custom?

  before_validation :strip_submission_comment

  scope :for_today, ->(date = Date.current) { where(assigned_date: date) }
  scope :actionable, -> { pending.or(awaiting_approval) }
  scope :in_period_for, ->(global_task, date) {
    where(assigned_date: ProfileTask.period_range(global_task, date))
  }
  scope :consuming_slot, -> { where(status: %i[awaiting_approval approved]) }

  def self.period_range(global_task, date)
    case global_task.frequency.to_s
    when "weekly"
      week_start_sym = global_task.family.week_start.to_i.zero? ? :sunday : :monday
      date.beginning_of_week(week_start_sym)..date.end_of_week(week_start_sym)
    when "monthly"
      date.beginning_of_month..date.end_of_month
    when "once"
      ONCE_PERIOD_FLOOR..date
    else
      date..date
    end
  end

  after_commit :broadcast_approval_count
  after_update_commit :remove_from_kid_dashboard, if: -> { saved_change_to_status? && (awaiting_approval? || approved?) }
  after_create_commit :broadcast_pending_to_kid_dashboard, if: :pending_with_global_task?

  def title
    custom? ? custom_title : global_task&.title
  end

  def description
    custom? ? custom_description : global_task&.description
  end

  def points
    custom? ? custom_points : global_task&.points
  end

  def category
    custom? ? custom_category : global_task&.category
  end

  def icon
    custom? ? nil : global_task&.icon
  end

  private

  def catalog_requires_global_task
    if global_task.blank? && global_task_id.blank?
      errors.add(:global_task_id, :blank)
    end
  end

  def custom_requires_category
    if custom_category.blank? && custom_category_id.blank?
      errors.add(:custom_category_id, :blank)
    end
  end

  def custom_rejects_global_task
    if global_task.present? || global_task_id.present?
      errors.add(:global_task_id, :present)
    end
  end

  def strip_submission_comment
    self.submission_comment = submission_comment.to_s.strip.presence
  end

  def proof_photo_valid
    if proof_photo.blob.byte_size > PROOF_PHOTO_MAX_SIZE
      errors.add(:proof_photo, :too_large, message: "must be smaller than 5 MB")
    end

    unless PROOF_PHOTO_CONTENT_TYPES.include?(proof_photo.blob.content_type)
      errors.add(:proof_photo, :invalid_content_type, message: "must be a JPEG, PNG, or WebP image")
    end
  end

  def broadcast_approval_count
    family_id = Profile.where(id: profile_id).pick(:family_id)
    return unless family_id

    count = ProfileTask.joins(:profile).where(profiles: { family_id: family_id }).awaiting_approval.count

    broadcast_update_to Family.new(id: family_id), "approvals",
      target: "pending_approvals_count",
      html: count.to_s
  end

  def remove_from_kid_dashboard
    broadcast_remove_to Profile.find(profile_id), "notifications", target: self
  end

  def pending_with_global_task?
    pending? && global_task_id.present?
  end

  def broadcast_pending_to_kid_dashboard
    Turbo::StreamsChannel.broadcast_append_to(
      "kid_#{profile_id}",
      target: "panel-pending",
      partial: "kid/dashboard/pending_card",
      locals: { profile_task: self, index: 0 }
    )
  rescue StandardError => e
    Rails.logger.warn("[ProfileTask] broadcast pending failed id=#{id} error=#{e.message}")
  end
end
