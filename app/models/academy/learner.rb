# frozen_string_literal: true

module Academy
  # Boundary value object. The Academy module knows nothing about Profile,
  # Family, or any host model — it only knows a learner has an id, a display
  # name, and an age band ("kid" by default). Build one in the host:
  #
  #   Academy::Learner.from_profile(current_profile)
  # Interest entry resolved at the host boundary (key + label) so the
  # Academy module never reaches into ProfileInterest::Catalog directly.
  Interest = Data.define(:key, :label) do
    def to_s = label.to_s
  end

  Learner = Data.define(:id, :display_name, :age_band, :timezone, :interests) do
    def self.from_profile(profile)
      keys = profile.respond_to?(:interest_keys) ? Array(profile.interest_keys) : []
      resolved = keys.map do |k|
        label = defined?(::ProfileInterest) ? ::ProfileInterest::Catalog.label_for(k) : k.to_s
        ::Academy::Interest.new(key: k, label: label)
      end
      new(
        id: profile.id,
        display_name: profile.name,
        age_band: profile.role == "child" ? "kid" : "adult",
        timezone: profile.family&.timezone.presence || "UTC",
        interests: resolved
      )
    end

    def kid?  = age_band == "kid"
    def top_interest = Array(interests).first
    def interest_keys = Array(interests).map(&:key)
  end

  # Keep the pre-existing 3-/4-keyword constructors working — `timezone` was
  # added after several callsites passed only the original three, and
  # `interests` was added after that. Default to UTC + empty array when
  # absent. Done via singleton alias rather than `super` inside the
  # `Data.define` block (which doesn't resolve cleanly on Ruby 3.3 Data classes).
  class << Learner
    alias_method :_data_new, :new
    def new(id:, display_name:, age_band:, timezone: "UTC", interests: [])
      _data_new(
        id: id, display_name: display_name, age_band: age_band,
        timezone: timezone, interests: Array(interests)
      )
    end
  end
end
