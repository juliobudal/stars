# frozen_string_literal: true

module Academy
  # Boundary value object. The Academy module knows nothing about Profile,
  # Family, or any host model — it only knows a learner has an id, a display
  # name, and an age band ("kid" by default). Build one in the host:
  #
  #   Academy::Learner.from_profile(current_profile)
  Learner = Data.define(:id, :display_name, :age_band, :timezone) do
    def self.from_profile(profile)
      new(
        id: profile.id,
        display_name: profile.name,
        age_band: profile.role == "child" ? "kid" : "adult",
        timezone: profile.family&.timezone.presence || "UTC"
      )
    end

    # Keep the pre-existing 3-keyword constructor working — modules added the
    # `timezone` field after several callsites already passed only the original
    # three. Default to UTC when absent.
    def self.new(id:, display_name:, age_band:, timezone: "UTC")
      super(id: id, display_name: display_name, age_band: age_band, timezone: timezone)
    end

    def kid?  = age_band == "kid"
  end
end
