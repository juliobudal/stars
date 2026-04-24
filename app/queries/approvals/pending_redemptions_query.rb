module Approvals
  class PendingRedemptionsQuery
    def initialize(family:)
      @family = family
    end

    def call
      Redemption
        .pending
        .includes(:profile, :reward)
        .joins(:profile)
        .where(profiles: { family_id: @family.id })
        .order(created_at: :desc)
    end
  end
end
