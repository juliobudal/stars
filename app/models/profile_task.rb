# == Schema Information
#
# Table name: profile_tasks
#
#  id             :bigint           not null, primary key
#  assigned_date  :date
#  completed_at   :datetime
#  status         :integer          default("pending")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  global_task_id :bigint           not null
#  profile_id     :bigint           not null
#
# Indexes
#
#  index_profile_tasks_on_global_task_id                (global_task_id)
#  index_profile_tasks_on_profile_id                    (profile_id)
#  index_profile_tasks_on_profile_id_and_assigned_date  (profile_id,assigned_date)
#  index_profile_tasks_on_profile_id_and_status         (profile_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (global_task_id => global_tasks.id)
#  fk_rails_...  (profile_id => profiles.id)
#
class ProfileTask < ApplicationRecord
  belongs_to :profile
  belongs_to :global_task

  has_one_attached :proof_photo

  enum :status, { pending: 0, awaiting_approval: 1, approved: 2, rejected: 3 }, default: :pending

  PROOF_PHOTO_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  PROOF_PHOTO_MAX_SIZE = 5.megabytes

  validate :proof_photo_valid, if: -> { proof_photo.attached? }

  delegate :title, :points, :category, :description, :icon, to: :global_task

  scope :for_today, ->(date = Date.current) { where(assigned_date: date) }
  scope :actionable, -> { pending.or(awaiting_approval) }

  after_commit :broadcast_approval_count
  after_update_commit :remove_from_kid_dashboard, if: -> { saved_change_to_status? && (awaiting_approval? || approved?) }

  private

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
    # Use profile_id for broadcast target
    broadcast_remove_to Profile.find(profile_id), "notifications", target: self
  end
end
