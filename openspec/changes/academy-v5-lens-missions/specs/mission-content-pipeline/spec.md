## ADDED Requirements

### Requirement: Mission seed shape is thin
`academy_missions` SHALL contain exactly the seed fields `slug`, `title`, `hook`, `learning_objective`, `concept_id`, `subject_id`, plus standard timestamps and an `active` flag. The columns `scenes_tree`, `sessions_count`, `teaser_for_next_mission_id`, and `format` SHALL NOT exist in the v5 schema.

#### Scenario: Legacy columns are absent from schema
- **WHEN** `db/schema.rb` is inspected
- **THEN** none of `scenes_tree`, `sessions_count`, `teaser_for_next_mission_id`, `format` are present on `academy_missions`

#### Scenario: Cutover migration drops legacy columns explicitly
- **WHEN** the v5 migration suite is reviewed
- **THEN** a migration explicitly drops the four legacy columns

### Requirement: Humans do not author lens bodies in the primary path
The admin UI SHALL NOT expose a "create lens body" form bound to a mission seed. The only sanctioned human content path is the override flow. The mission creation/edit form SHALL surface only the seed fields.

#### Scenario: Mission form has no body field
- **WHEN** the mission admin form is inspected
- **THEN** no rich-text or JSON field bound to a lens body is present

#### Scenario: Body params on mission save are ignored
- **WHEN** a curator posts a payload that includes a lens body field to the mission save endpoint
- **THEN** the body field is dropped or the request is rejected with 422

### Requirement: Admin override per concept and lens type
An admin SHALL be able to author a manual payload keyed by `(concept_id, lens_type, age_band, locale)`. At render time, the system SHALL prefer the override over any LLM-generated cache row matching the same key. Overrides SHALL validate against the same per-lens-type JSON schema as LLM output.

#### Scenario: Override wins at render time
- **WHEN** both an override and a cache row exist for the same key
- **THEN** the render returns the override payload

#### Scenario: Invalid override is rejected
- **WHEN** a curator saves an override that fails its lens-type JSON schema
- **THEN** the save is rejected with 422 and field-level errors

#### Scenario: Overrides are listed separately
- **WHEN** an admin opens the admin index
- **THEN** overrides have a dedicated listing, separate from mission seed admin

### Requirement: Mission seeds are versioned
Every write to `academy_missions` (create, update, deactivate) SHALL be captured in a version history table. The version row SHALL record actor, timestamp, and a full snapshot of seed fields. Reverting a mission to a prior version SHALL be possible from the admin UI.

#### Scenario: Three edits produce three version rows
- **WHEN** a mission is edited three times
- **THEN** three version rows exist for it

#### Scenario: Revert restores prior snapshot
- **WHEN** an admin reverts a mission to a prior version
- **THEN** the live seed fields equal that version's snapshot

### Requirement: Deactivation preserves learner history
Setting `active: false` on a mission SHALL NOT delete or anonymize any `LearnerLensVisit` row, `LearnerConcept` row, or completed mission attempt. Deactivated missions SHALL NOT appear in new-mission listings but SHALL remain readable in parent digests and learner history views.

#### Scenario: History survives deactivation
- **WHEN** a mission is deactivated
- **THEN** the learner's completed-missions history still includes it

#### Scenario: Kid picker excludes deactivated
- **WHEN** the kid mission picker is rendered
- **THEN** missions with `active: false` are excluded

### Requirement: Mission edits do not invalidate lens cache
Edits to a mission seed (title, hook, learning_objective) SHALL NOT delete or invalidate `academy_lens_cache` rows. The cache is keyed by concept, not mission, so seed edits SHALL be metadata-only.

#### Scenario: Hook edit preserves cache rows
- **WHEN** a mission's hook is edited
- **THEN** the count of `academy_lens_cache` rows is unchanged

#### Scenario: Edit screen documents non-invalidation
- **WHEN** an admin views the mission edit screen
- **THEN** a help text states "Editing this mission does not regenerate lens content"

### Requirement: Only template version or admin purge invalidates cache
Cache invalidation surface SHALL be exactly two paths: bumping a lens type's `template_version` (lazy invalidation), and explicit admin purge of one row or one `(lens_type, template_version)` group. No other code path SHALL invalidate cache rows.

#### Scenario: No service outside lens-generation deletes from cache
- **WHEN** `app/` is grepped for deletes against `academy_lens_cache`
- **THEN** only services within the `lens-generation` capability appear

#### Scenario: Concept rename leaves cache intact
- **WHEN** a concept's slug or title is renamed
- **THEN** all cache rows for that `concept_id` remain present and queryable
