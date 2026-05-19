# frozen_string_literal: true

module Academy
  class ApplicationRecord < ::ApplicationRecord
    self.abstract_class = true

    # Host enables `strict_loading_by_default` globally. Inside the Academy
    # module, services own the access patterns end-to-end and lazy chains
    # like `session.mission` (delegated to mission_progress) are intentional.
    # Opt out here so the module boundary stays ergonomic without disabling
    # strict loading for the host.
    self.strict_loading_by_default = false
  end
end
