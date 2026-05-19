# frozen_string_literal: true

module Academy
  # Mirrors host ApplicationService contract on purpose — the module returns
  # the same Result shape so host controllers can treat module services
  # identically to host services without importing host code.
  class ApplicationService < ::ApplicationService
  end
end
