class ProfileTask < ApplicationRecord
  belongs_to :profile
  belongs_to :global_task

  enum :status, { pending: 0, awaiting_approval: 1, approved: 2, rejected: 3 }, default: :pending

  delegate :title, :points, :category, :description, :icon, to: :global_task

  scope :for_today, -> { where(assigned_date: Date.current) }
  scope :actionable, -> { pending.or(awaiting_approval) }

  after_commit :broadcast_approval_count
  after_update_commit :remove_from_kid_dashboard, if: -> { saved_change_to_status? && (awaiting_approval? || approved?) }

  private

  def broadcast_approval_count
    # Use direct queries to avoid strict loading violations on associations
    # We pluck family_id from Profile to avoid triggering association load
    family_id = Profile.where(id: profile_id).pluck(:family_id).first
    return unless family_id

    count = ProfileTask.joins(:profile).where(profiles: { family_id: family_id }).awaiting_approval.count

    broadcast_update_to Family.find(family_id), "approvals",
      target: "pending_approvals_count",
      html: count.to_s
  end

  def remove_from_kid_dashboard
    # Use profile_id for broadcast target
    broadcast_remove_to Profile.find(profile_id), "notifications", target: self
  end
end
