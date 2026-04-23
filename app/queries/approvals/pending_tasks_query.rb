module Approvals
  class PendingTasksQuery
    def initialize(family:)
      @family = family
    end

    def call
      ProfileTask
        .awaiting_approval
        .includes(:profile, :global_task)
        .joins(:profile)
        .where(profiles: { family_id: @family.id })
        .order("profiles.name ASC, profile_tasks.created_at DESC")
    end
  end
end
