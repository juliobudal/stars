# frozen_string_literal: true

module Academy
  # Boundary value object: a pure (key + label) interest pair resolved by the
  # host (see Kid::Academy::BaseController#build_learner) before it crosses into
  # the Academy module. The module never reaches back into host models such as
  # ProfileInterest::Catalog.
  #
  # Lives in its own file (not alongside Academy::Learner) so Zeitwerk can
  # autoload it: referencing ::Academy::Interest before ::Academy::Learner
  # otherwise raises "uninitialized constant Academy::Interest" in development.
  Interest = Data.define(:key, :label) do
    def to_s = label.to_s
  end
end
