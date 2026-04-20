class ProfileTask < ApplicationRecord
  belongs_to :profile
  belongs_to :global_task

  enum :status, {pending: 0, awaiting_approval: 1, approved: 2, rejected: 3}, default: :pending

  delegate :title, :points, :category, :description, :icon, to: :global_task

  scope :for_today, -> { where(assigned_date: Date.current) }
  scope :actionable, -> { pending.or(awaiting_approval) }

  after_commit :broadcast_approval_count
  after_update_commit :remove_from_kid_dashboard, if: -> { saved_change_to_status? && (awaiting_approval? || approved?) }

  private

  def broadcast_approval_count
    # Note: Use family_id to avoid unnecessary loads
    family = profile.family
    broadcast_update_to family, "approvals",
      target: "pending_approvals_count",
      html: family.profile_tasks.awaiting_approval.count.to_s
  end

  def remove_from_kid_dashboard
    broadcast_remove_to profile, "notifications", target: self
  end
end
