module Approvals
  class PendingRedemptionsQuery
    def initialize(family:)
      @family = family
    end

    def call
      Redemption
        .pending
        .includes(:profile, :reward)
        .where(profiles: { family_id: @family.id })
        .references(:profiles)
        .order(created_at: :desc)
    end
  end
end
