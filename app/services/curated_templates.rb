# frozen_string_literal: true

# Shared lookups for the curated template libraries (Tasks::TemplateLibrary,
# Rewards::TemplateLibrary). The including module only declares a frozen
# TEMPLATES array of `{ key: ... }` hashes; `extend CuratedTemplates` grants the
# common `all`/`find` accessors so the two libraries can't drift in how they
# resolve keys.
module CuratedTemplates
  def all
    self::TEMPLATES
  end

  def find(key)
    self::TEMPLATES.find { |t| t[:key] == key.to_s }
  end
end
