## ADDED Requirements

### Requirement: Four-level depth ladder with explicit semantics
`LearnerConcept.level` SHALL take exactly one of `{0, 1, 2, 3}` with the following meanings: L0 = no `LearnerLensVisit` exists for this learner+concept; L1 = at least one `LearnerLensVisit` exists and no mission has been completed; L2 = at least one mission attempt for this concept has been `completed`; L3 = at least two completed missions for this concept exist in at least two distinct Subjects.

#### Scenario: Level column is range-constrained
- **WHEN** the schema is inspected
- **THEN** `academy_learner_concepts.level` is constrained to integer values in `[0, 3]`

#### Scenario: Single-subject mass-completion stays L2
- **WHEN** a learner has 5 completed missions for the same concept all within one Subject
- **THEN** the learner's level for that concept is 2, not 3

#### Scenario: Cross-subject completions reach L3
- **WHEN** a learner has 2 completed missions for the same concept in 2 different Subjects
- **THEN** the learner's level for that concept becomes 3

### Requirement: Promotion is monotonic
Pokédex level transitions SHALL be monotonic under normal operation. The service SHALL NOT decrement a learner's level via routine code paths. The only sanctioned downgrade is an admin data-correction action that SHALL emit a `pokedex_downgrade` audit event.

#### Scenario: Routine writes never lower a level
- **WHEN** `Pokedex::Advance` evaluates a learner whose recorded level exceeds the new computed level
- **THEN** no write occurs and the row remains at the higher level

#### Scenario: Admin downgrade is audited
- **WHEN** an admin issues a downgrade action
- **THEN** an audit row records actor, reason, before-level, and after-level

### Requirement: Pokedex Advance is idempotent
The promotion service SHALL be safe to call multiple times for the same `mission_completed` event. Re-delivery of an event SHALL NOT trigger a duplicate level change, a duplicate Turbo Stream broadcast, or a duplicate animation cue.

#### Scenario: Re-delivery causes no duplicate write
- **WHEN** the same event id is delivered twice
- **THEN** at most one level-change write occurs and at most one Turbo Stream broadcast is emitted

#### Scenario: Dedup state is persisted
- **WHEN** an event is processed
- **THEN** its id is recorded in a `processed_event_ids` table or column to short-circuit re-delivery

### Requirement: Promotion is event-driven
`Pokedex::Advance` SHALL be invoked only via subscription to `mission_completed` (and the audited admin path). The service SHALL NOT scan the missions table on a schedule.

#### Scenario: No cron triggers promotion
- **WHEN** the cron/recurring configuration is inspected
- **THEN** no scheduled job invokes `Pokedex::Advance`

#### Scenario: Handler is registered on the event
- **WHEN** the event bus configuration is inspected
- **THEN** `Pokedex::Advance` is subscribed to `mission_completed`

### Requirement: Evolution broadcasts a Turbo Stream
On any successful level change (L0→L1, L1→L2, L2→L3), the service SHALL broadcast a Turbo Stream to the `learner_#{learner_id}_pokedex` channel carrying the updated concept tile. Visual orb classes SHALL map as L0→silhouette, L1→spotted, L2→recognized, L3→mastered, reusing the existing CSS classes.

#### Scenario: Orb class updates on promotion
- **WHEN** a learner's level for a concept transitions from L1 to L2
- **THEN** the Atlas tile receives a Turbo Stream that updates the orb class to `pokedex-orb--recognized`

#### Scenario: Broadcast fires even without active subscriber
- **WHEN** a learner is not viewing the Pokédex at the time of promotion
- **THEN** the Turbo Stream is still emitted unconditionally

### Requirement: Reladdering job re-derives v4 data
A one-shot data migration job SHALL recompute `LearnerConcept.level` for every existing row based solely on v5 evidence: `LearnerLensVisit` rows (for L1), completed v5 mission attempts (for L2), and cross-subject completed attempts (for L3). The job SHALL NOT trust the pre-existing `level` value.

#### Scenario: Job converges
- **WHEN** the reladdering job is run twice consecutively
- **THEN** the second run reports zero level changes

#### Scenario: Dry-run reports deltas without writing
- **WHEN** the job is invoked in dry-run mode
- **THEN** it reports counts of learners moving up, down, and unchanged with no database mutations

### Requirement: Tile render is single-query
Rendering the full Pokédex Atlas for one learner SHALL be possible in a single SQL query joining `academy_concepts` and `academy_learner_concepts`. The view layer SHALL NOT issue per-tile queries.

#### Scenario: Strict-loading passes on large Pokédex
- **WHEN** the Atlas controller renders for a learner with 200+ concepts
- **THEN** the strict-loading guard does not fire

#### Scenario: One SELECT against learner concepts
- **WHEN** a view spec instruments database access during Atlas render
- **THEN** at most one `SELECT` against `academy_learner_concepts` is observed

### Requirement: L3 reads from completed attempts only
The L2→L3 promotion check SHALL count completed mission attempts grouped by Subject — not lens-type diversity, not visit count. `closed_without_transfer` attempts SHALL NOT contribute to L2 or L3.

#### Scenario: Without-transfer attempts do not promote
- **WHEN** a learner has 1 completed and 5 `closed_without_transfer` attempts on the same concept
- **THEN** the learner remains at L2

#### Scenario: Same-subject mass completion does not reach L3
- **WHEN** a learner has 2 completed attempts on the same concept in the same Subject
- **THEN** the learner remains at L2
