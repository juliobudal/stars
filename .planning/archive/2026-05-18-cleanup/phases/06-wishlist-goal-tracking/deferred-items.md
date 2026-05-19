# Deferred Items - Phase 06

Items discovered during execution that are out of scope for the current plan. Logged for follow-up.

## Pre-existing annotation drift (out of scope)

**Discovered during:** Plan 06-01, Task 2 (running `bundle exec annotaterb models` to refresh `Profile` schema header)

**Files affected:**
- `app/models/global_task.rb`
- `spec/models/global_task_spec.rb`
- `spec/factories/global_tasks.rb`

**Symptom:** Annotaterb regenerated schema headers to include the `featured` column and the `index_global_tasks_on_family_id_and_featured` index (added by migrations `20260429200942_add_max_completions_per_period_to_global_tasks.rb` and `20260430124818_add_featured_to_global_tasks.rb`). These annotation refreshes were never committed when those migrations landed.

**Action taken in 06-01:** Reverted the unrelated diffs (`git checkout -- app/models/global_task.rb spec/factories/global_tasks.rb spec/models/global_task_spec.rb`) so Plan 06-01's commits stay focused on the Profile/wishlist scope. Drift persists.

**Recommended follow-up:** A small chore commit running `make shell` then `bundle exec annotaterb models` and committing only the global_task-related files. Not blocking for Phase 06.

## Migration lint drift (out of scope)

**Discovered during:** Plan 06-02, Task 1 (running `make lint` after creating `Profiles::SetWishlistService`)

**File affected:**
- `db/migrate/20260501000924_add_wishlist_reward_id_to_profiles.rb`

**Symptom:** Two `Layout/SpaceInsideHashLiteralBraces` rubocop offences on line 4 (`foreign_key: {to_table: :rewards, on_delete: :nullify}`). Plan 06-01's "Deviation #3" notes that standardrb auto-corrected to no-spaces, but the project rubocop config (`rubocop-rails-omakase`) requires spaces — the two linters disagree on this hash style.

**Action taken in 06-02:** Left untouched. New 06-02 file (`app/services/profiles/set_wishlist_service.rb`) lints clean (0 offences).

**Recommended follow-up:** Resolve the standardrb-vs-rubocop hash-spacing conflict at the project level (either align configs or accept a single auto-correct pass). Not blocking for Phase 06.
