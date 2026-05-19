## ADDED Requirements

### Requirement: Mission teaches exactly one focus concept
A Mission SHALL reference exactly one Concept via a non-null `concept_id` column. The system SHALL NOT support multi-concept missions; the v4 `academy_aula_concepts` join table SHALL NOT be used by v5 code paths.

#### Scenario: Schema enforces single concept
- **WHEN** the database schema is inspected
- **THEN** `academy_missions.concept_id` is `NOT NULL` with a FK to `academy_concepts`

#### Scenario: Validation blocks conceptless missions
- **WHEN** code attempts to construct a Mission without a concept
- **THEN** model validation fails before persistence

#### Scenario: V5 services never read the legacy join
- **WHEN** any v5 service path is exercised
- **THEN** no SQL touches `academy_aula_concepts`

### Requirement: Every mission is a lens journey
The mission runner SHALL render the mission as an ordered sequence of lens visits. There SHALL NOT exist a code path that completes a mission without at least one `LearnerLensVisit` record. The legacy `mission.format` enum and chat-based flows SHALL NOT be reachable in v5.

#### Scenario: Completion requires at least one visit
- **WHEN** a mission attempt has zero `LearnerLensVisit` rows
- **THEN** transition to `completed` is rejected

#### Scenario: Controller resolves through Lens services only
- **WHEN** the mission show controller is grepped
- **THEN** no reference to `AdvanceTurn`, `StartMission`, `GuideAgent`, or `GuidePersona` is found

### Requirement: System selects the next lens
On every lens transition (mission open and after each lens close), the system SHALL call an adaptive ordering service that returns the next lens type. The learner SHALL NOT be presented with a choice of which lens type comes next within a live mission attempt.

#### Scenario: No learner-facing next-lens picker
- **WHEN** a kid views a mission stage
- **THEN** no UI affordance offers to pick the next lens type

#### Scenario: Ordering inputs are recorded per visit
- **WHEN** a `LearnerLensVisit` row is created
- **THEN** it records `chooser_version` and the inputs consulted by ordering

#### Scenario: Pokédex revisit does not create attempt visits
- **WHEN** a learner taps a concept tile on the Pokédex to revisit a lens
- **THEN** no new `LearnerLensVisit` row is created on any active mission attempt

### Requirement: Ordering honors diversity and pedagogical heuristics
The ordering service SHALL NOT return the same lens type twice in a row within one mission attempt and SHALL prefer concrete-before-abstract (narrative/first_person/historical before statistical/scientific) and place a closure lens last. The service SHALL consume signals from prior visits in the same attempt.

#### Scenario: No consecutive same-type pairs
- **WHEN** 1,000 simulated mission attempts are run
- **THEN** zero consecutive same-type lens pairs occur

#### Scenario: Openers are concrete
- **WHEN** an attempt opens with alternatives available
- **THEN** the first lens is not `statistical` or `scientific`

#### Scenario: Closure type ends every attempt
- **WHEN** an attempt completes successfully
- **THEN** the terminating lens is `analogy_bridge` or `ethical`

### Requirement: Mission closure conditions
A mission attempt SHALL be eligible for closure when BOTH conditions hold: (a) the learner has visited lenses of at least 4 distinct catalog lens types, AND (b) at least one of the visited lenses is of a closure type (`analogy_bridge` or `ethical`). A mission attempt SHALL be force-closed if 7 lenses have been visited regardless of diversity.

#### Scenario: Insufficient diversity blocks completion
- **WHEN** an attempt has visited only 3 distinct lens types even after 6 visits
- **THEN** the attempt cannot transition to `completed`

#### Scenario: Missing closure lens blocks completion
- **WHEN** an attempt has 4 distinct lens types but none are closure-type
- **THEN** the attempt cannot transition to `completed`

#### Scenario: Cap forces termination without transfer
- **WHEN** the 7th visit closes and no closure-type lens has been visited
- **THEN** the attempt is marked `closed_without_transfer`, not `completed`

### Requirement: LearnerLensVisit is the visit ledger
Every lens render SHALL create a `LearnerLensVisit` row at open with `opened_at` set, and SHALL update `closed_at` plus serialized interaction summary at close. The row SHALL persist `mission_attempt_id`, `concept_id`, `lens_type`, `lens_cache_id`, `ordering_position`, and `signals` (jsonb).

#### Scenario: Visit slots are unique per attempt
- **WHEN** the database schema is inspected
- **THEN** `(mission_attempt_id, ordering_position)` has a unique constraint

#### Scenario: In-flight visits have no close timestamp
- **WHEN** a visit row is created
- **THEN** `opened_at` is non-null and `closed_at` is null until the lens is closed

### Requirement: Each lens visit emits one Signal record
On lens close, the runner SHALL emit exactly one Signal row capturing `time_on_lens_ms`, `micro_check_correct` (nullable), `affective_tap` (nullable enum), and `abandoned` (boolean). Signals SHALL be queryable by `(learner_id, concept_id, lens_type)` for the adaptive ordering service.

#### Scenario: Exactly one signal per closed visit
- **WHEN** a `LearnerLensVisit` transitions to closed
- **THEN** exactly one Signal row references it

#### Scenario: Signal lookup is index-backed
- **WHEN** ordering queries signals for a learner+concept+lens_type
- **THEN** a composite index on `(learner_id, concept_id, lens_type, created_at)` serves the query

### Requirement: Abandonment preserves lens position
If a learner exits a mission attempt mid-lens (closes browser, navigates away, app crashes), the mission attempt SHALL remain `in_progress` with the open `LearnerLensVisit` retained. When the learner resumes, the runner SHALL re-render the same lens (same `lens_cache_id`, same `ordering_position`) rather than re-deciding the next lens.

#### Scenario: Resume returns the same lens
- **WHEN** a learner abandons during lens A and later resumes the same attempt
- **THEN** lens A is re-rendered with the same `lens_cache_id` and `ordering_position`

#### Scenario: Resume does not call the ordering service
- **WHEN** a resume happens while an open `LearnerLensVisit` exists
- **THEN** the ordering service is not invoked

### Requirement: Mission completion emits a domain event
On successful closure, the system SHALL publish a `mission_completed` event carrying `{learner_id, mission_id, concept_id, attempt_id, visited_lens_types, completed_at}`. Downstream consumers SHALL subscribe to this event and SHALL NOT poll the mission table.

#### Scenario: Event is idempotent under retry
- **WHEN** the same attempt completion is re-delivered
- **THEN** the event fires exactly once for downstream consumers

#### Scenario: Without-transfer outcome publishes a different event
- **WHEN** an attempt force-closes without visiting a closure lens
- **THEN** the system publishes `mission_closed_without_transfer`, not `mission_completed`

### Requirement: Mission attempt is replayable read
Any consumer (digest, parent view, learner Pokédex tap) SHALL be able to read the full ordered lens sequence of a completed attempt via a single query joining `mission_attempts` and `LearnerLensVisit`. The mission attempt SHALL NOT expose lens payloads inline — only references to `lens_cache_id`.

#### Scenario: Summary render is one-query plus N cache reads
- **WHEN** a controller renders a completed attempt summary
- **THEN** it issues one SQL query for the visit sequence and N cache reads for payloads

#### Scenario: No payload duplication on visit rows
- **WHEN** the `LearnerLensVisit` table is scanned
- **THEN** no serialized lens body is present on visit or attempt rows
