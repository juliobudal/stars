# Run using bin/ci

CI.run do
  test_db = ENV.fetch("TEST_DATABASE_URL", "postgres://littlestars:littlestars_dev@db:5432/littlestars_test")

  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"
  step "Style: Motion tokens", "bash scripts/check-motion-tokens.sh"
  step "Style: JS syntax", "bash scripts/check-js-syntax.sh"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Assets: Vite build", "bin/vite build"
  step "Tests: RSpec", "env RAILS_ENV=test DATABASE_URL=#{test_db} bin/rails db:environment:set && env RAILS_ENV=test DATABASE_URL=#{test_db} bundle exec rspec --exclude-pattern 'spec/system/**/*_spec.rb'"
  step "Tests: Seeds", "env RAILS_ENV=test DATABASE_URL=#{test_db} bin/rails db:environment:set db:seed:replant"
  # v4 Guide persona eval removed during academy-v5-lens-missions refoundation.
  # A fresh v5 persona eval will be reintroduced in Phase 8 (T-V5-089b).

  # Optional: Run system tests
  # step "Tests: System", "bin/rails test:system"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
