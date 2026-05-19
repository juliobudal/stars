## ADDED Requirements

### Requirement: Closed lens catalog
The system SHALL recognize exactly the 8 catalog lens types: `scientific`, `narrative`, `ethical`, `statistical`, `engineering`, `historical`, `first_person`, `analogy_bridge`. Adding a new lens type SHALL require a code change, a new prompt template with a JSON schema, and a migration of `academy_lens_cache.lens_type`.

#### Scenario: Lens type column is constrained
- **WHEN** the schema is inspected
- **THEN** `academy_lens_cache.lens_type` is a database-level enum or check-constrained string with exactly the 8 values

#### Scenario: No free-form lens type at runtime
- **WHEN** a request submits a lens type not in the catalog
- **THEN** the request is rejected before any LLM invocation

### Requirement: Per-lens-type prompt template with version
Each lens type SHALL have exactly one active prompt template at any time, identified by a `template_version`. Templates SHALL be stored in source-controlled files under `app/services/academy/lens/templates/` and loaded at boot — not edited from the admin UI.

#### Scenario: Templates are deploy-gated
- **WHEN** an admin attempts to edit a prompt template via the UI
- **THEN** no such affordance exists in the admin surface

#### Scenario: Template version is recorded on cache rows
- **WHEN** `Lens::Generate` writes a cache row
- **THEN** the `template_version` used is persisted on the row

### Requirement: Cache key is the five-tuple
A cache row SHALL be uniquely identified by `(concept_id, lens_type, age_band, locale, template_version)`. The system SHALL enforce a unique index on this tuple. Two requests with the same tuple SHALL return the same payload without re-invoking the LLM.

#### Scenario: Unique constraint on the cache tuple
- **WHEN** the schema is inspected
- **THEN** a unique index exists on `(concept_id, lens_type, age_band, locale, template_version)` of `academy_lens_cache`

#### Scenario: Second read does not invoke the LLM
- **WHEN** `Lens::Generate` is called twice with the same tuple
- **THEN** the LLM client is invoked at most once

### Requirement: Output validates before caching
Every LLM response SHALL be validated against the per-lens-type JSON schema before being persisted to the cache. Validation failures SHALL NOT result in a cached row.

#### Scenario: Invalid output is never cached
- **WHEN** the LLM returns a payload that fails its schema
- **THEN** no row is written to `academy_lens_cache` for that attempt

#### Scenario: Schemas exist for every catalog type
- **WHEN** the app boots
- **THEN** a schema file is present under `app/services/academy/lens/schemas/` for each of the 8 lens types

### Requirement: Failed generations retry without caching
If the LLM call fails (timeout, 5xx, schema-invalid output, refusal), the system SHALL retry up to a configured limit with exponential backoff. Each failed attempt SHALL be logged with `concept_id`, `lens_type`, `template_version`, and failure reason. A final failure SHALL surface as a structured error to the caller and SHALL NOT write any cache row.

#### Scenario: Final failure raises a typed error
- **WHEN** the retry budget is exhausted
- **THEN** the caller receives `Lens::GenerationFailed` with a typed failure reason

#### Scenario: Cache contains no null payloads
- **WHEN** the `academy_lens_cache` table is scanned
- **THEN** no row has `payload IS NULL`

### Requirement: Personalization tokens never enter the cache
Tokens such as `{{learner_name}}` and `{{family_member_a}}` SHALL appear verbatim in the cached payload. Token resolution SHALL occur in a render step downstream of cache read, with the resolved string never persisted back to the cache row.

#### Scenario: No PII in cached payloads
- **WHEN** `academy_lens_cache.payload` is scanned for known learner identifiers
- **THEN** zero matches are returned

#### Scenario: Tokens resolved in-memory at render
- **WHEN** a personalization service substitutes tokens for a specific learner
- **THEN** the resolved string is not written back to the cache row

### Requirement: Concurrent misses serialize to one LLM call
If two requests miss the cache for the same five-tuple simultaneously, the system SHALL serialize generation such that exactly one LLM call is made and both requests return the same payload. The implementation SHALL use an upsert with `ON CONFLICT DO NOTHING` or a row-level advisory lock — never a read-then-write check.

#### Scenario: Fifty parallel misses produce one invocation
- **WHEN** 50 parallel `Lens::Generate` calls miss the cache for the same tuple
- **THEN** the LLM client mock records exactly one invocation

### Requirement: Warm-up job pre-generates cold lenses
A background job SHALL run on a schedule (default daily) and, for each active learner, identify the most likely next mission and pre-generate uncached lenses of types likely to be served. The job SHALL be safe to re-run and SHALL NOT regenerate already-cached entries.

#### Scenario: Warm cache yields zero LLM calls
- **WHEN** the warm-up job runs while the relevant cache is already warm
- **THEN** the LLM client receives zero invocations during the run

#### Scenario: Warm-up emits observability metrics
- **WHEN** the warm-up job finishes
- **THEN** it records `lenses_warmed_count` and `llm_calls_made` metrics

### Requirement: Admin can purge a cache row
An admin-authenticated endpoint SHALL allow deletion of a single cache row by its five-tuple, forcing regeneration on next read. Bulk purge SHALL be available scoped to `(lens_type, template_version)` to support template rollouts.

#### Scenario: Purge is audit-logged
- **WHEN** an admin purges a cache row
- **THEN** an audit log entry records admin id, timestamp, and key

#### Scenario: In-flight visits unaffected by mid-flight purge
- **WHEN** a cache row is purged while an in-flight `LearnerLensVisit` references it via `lens_cache_id`
- **THEN** the in-flight visit continues to render with the payload it captured at open

### Requirement: Template version bump invalidates only by reference
Bumping a prompt template's `template_version` SHALL NOT delete existing cache rows. New reads SHALL naturally miss the cache for the new version and generate fresh rows. Old rows SHALL remain readable as long as any `LearnerLensVisit` references them via `lens_cache_id`.

#### Scenario: Old rows survive a version bump
- **WHEN** a template version is bumped
- **THEN** existing cache rows under the previous version remain present and queryable

#### Scenario: New version triggers fresh generation
- **WHEN** a new attempt requests a lens with the bumped version
- **THEN** a new cache row is created under the new `template_version`
