# frozen_string_literal: true

# v4 story_choice missions are retired. In v5, narrative-bifurcation lives
# as the `narrative` lens type, curated under
# db/seeds/academy_lens_payloads/narrative/. This seed file is intentionally
# a no-op — kept as a placeholder so loaders that
# `load Rails.root.join("db/seeds/academy_stories.rb")` don't blow up.

puts "✓ Academy v5 story seed: skipped (v4 story_choice retired — see academy-v5-lens-missions)."
