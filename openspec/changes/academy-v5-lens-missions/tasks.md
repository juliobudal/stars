> See `tasks-detailed.md` for full Scope/Files/Dep/Aceite per task.
> Numbering format: `N.M T-V5-NNN — title` (N=phase, M=position-in-phase, T-V5-NNN traceability).

## 1. Foundations + dead-code wipe

- [x] 1.1 T-V5-001 — Add `concept_id` FK to `academy_missions`
  - Files: db/migrate/20260520000001_add_concept_id_to_academy_missions.rb
- [x] 1.2 T-V5-002 — Backfill `mission.concept_id` from primary `aula_concept`
  - Files: db/migrate/20260520000002_backfill_mission_concept_id.rb
  - Dep: T-V5-001
- [x] 1.3 T-V5-003 — Make `mission.concept_id` NOT NULL
  - Files: db/migrate/20260520000003_require_mission_concept_id.rb
  - Dep: T-V5-002
- [x] 1.4 T-V5-004 — Drop dead columns from `academy_missions`
  - Files: db/migrate/20260520000004_drop_v4_columns_from_academy_missions.rb
  - Dep: T-V5-003, T-V5-031
- [x] 1.5 T-V5-005 — Drop `academy_aula_concepts` table
  - Files: db/migrate/20260520000005_drop_academy_aula_concepts.rb
  - Dep: T-V5-003, T-V5-031
- [x] 1.6 T-V5-006 — Create `academy_lens_cache` table
  - Files: db/migrate/20260520000006_create_academy_lens_cache.rb
- [x] 1.7 T-V5-007 — Create `academy_learner_lens_visits` table
  - Files: db/migrate/20260520000007_create_academy_learner_lens_visits.rb
- [x] 1.8 T-V5-008 — Create `academy_lens_signals` table
  - Files: db/migrate/20260520000008_create_academy_lens_signals.rb
- [x] 1.9 T-V5-031 — Delete `Academy::AdvanceTurn` + `Academy::StartMission`
  - Files: app/services/academy/advance_turn.rb, app/services/academy/start_mission.rb
- [x] 1.10 T-V5-032 — Delete `Academy::Llm::GuidePersona` + `Llm::GuideAgent`
  - Files: app/services/academy/llm/guide_persona.rb, app/services/academy/llm/guide_agent.rb
- [x] 1.11 T-V5-033 — Delete chat views (mission show + parciais)
  - Files: app/views/kid/academy/missions/show.html.erb, app/views/kid/academy/missions/_message.html.erb, app/views/kid/academy/missions/_typing.html.erb, app/views/kid/academy/missions/_composer.html.erb
  - Dep: T-V5-031
- [x] 1.12 T-V5-034 — Delete Stimulus chat controllers
  - Files: app/assets/controllers/academy_chat_controller.js
- [x] 1.13 T-V5-035 — Delete persona v4 eval suite
  - Files: spec/services/academy/llm/persona_v4_eval_spec.rb, Makefile, config/ci.rb
  - Dep: T-V5-032
- [x] 1.14 T-V5-036 — Review `Academy::Cards::MintAfterMission` (KEEP)
  - Files: app/services/academy/cards/mint_after_mission.rb
- [x] 1.15 T-V5-037 — Review `Academy::Llm::Parser` (delete if unused)
  - Files: app/services/academy/llm/parser.rb
  - Dep: T-V5-031, T-V5-032
- [x] 1.16 T-V5-038 — Cleanup orphan factories/specs after wipe
  - Files: spec/factories/academy/, spec/services/academy/
  - Dep: T-V5-031, T-V5-032, T-V5-033, T-V5-034, T-V5-035, T-V5-036, T-V5-037

## 2. Lens catalog + generation pipeline

- [x] 2.1 T-V5-040 — `Academy::Lens::Catalog` constant with 8 lens types
  - Files: app/services/academy/lens/catalog.rb
- [x] 2.2 T-V5-041 — JSON output schemas per lens type (8 files)
  - Files: app/services/academy/lens/schemas/scientific.json, app/services/academy/lens/schemas/narrative.json, app/services/academy/lens/schemas/ethical.json, app/services/academy/lens/schemas/statistical.json, app/services/academy/lens/schemas/engineering.json, app/services/academy/lens/schemas/historical.json, app/services/academy/lens/schemas/first_person.json, app/services/academy/lens/schemas/analogy_bridge.json
  - Dep: T-V5-040
- [x] 2.3 T-V5-042 — Prompt template `scientific.md.erb`
  - Files: app/services/academy/lens/prompts/scientific.md.erb
- [x] 2.4 T-V5-043 — Prompt template `narrative.md.erb`
  - Files: app/services/academy/lens/prompts/narrative.md.erb
- [x] 2.5 T-V5-044 — Prompt template `ethical.md.erb`
  - Files: app/services/academy/lens/prompts/ethical.md.erb
- [x] 2.6 T-V5-045 — Prompt template `statistical.md.erb`
  - Files: app/services/academy/lens/prompts/statistical.md.erb
- [x] 2.7 T-V5-046 — Prompt template `engineering.md.erb`
  - Files: app/services/academy/lens/prompts/engineering.md.erb
- [x] 2.8 T-V5-047 — Prompt template `historical.md.erb`
  - Files: app/services/academy/lens/prompts/historical.md.erb
- [x] 2.9 T-V5-048 — Prompt template `first_person.md.erb`
  - Files: app/services/academy/lens/prompts/first_person.md.erb
- [x] 2.10 T-V5-049 — Prompt template `analogy_bridge.md.erb`
  - Files: app/services/academy/lens/prompts/analogy_bridge.md.erb
- [x] 2.11 T-V5-050 — `Academy::Lens::Generators::Base` abstract generator
  - Files: app/services/academy/lens/generators/base.rb
  - Dep: T-V5-040, T-V5-041
- [x] 2.12 T-V5-051 — Generator subclasses for the 8 lens types
  - Files: app/services/academy/lens/generators/scientific.rb, app/services/academy/lens/generators/narrative.rb, app/services/academy/lens/generators/ethical.rb, app/services/academy/lens/generators/statistical.rb, app/services/academy/lens/generators/engineering.rb, app/services/academy/lens/generators/historical.rb, app/services/academy/lens/generators/first_person.rb, app/services/academy/lens/generators/analogy_bridge.rb
  - Dep: T-V5-050
- [x] 2.13 T-V5-052 — `Academy::Lens::Generate` cache-aware entry point
  - Files: app/services/academy/lens/generate.rb
  - Dep: T-V5-006, T-V5-051
- [x] 2.14 T-V5-053 — `Academy::Lens::WarmCacheJob` nightly warmer
  - Files: app/jobs/academy/lens/warm_cache_job.rb, config/recurring.yml
  - Dep: T-V5-052

## 3. Ordering service

- [x] 3.1 T-V5-060 — `Academy::Lens::ChooseNext` adaptive ordering service
  - Files: app/services/academy/lens/choose_next.rb
  - Dep: T-V5-007, T-V5-008, T-V5-052
- [x] 3.2 T-V5-061 — `Academy::Lens::ScoreVisit` signal extractor
  - Files: app/services/academy/lens/score_visit.rb
  - Dep: T-V5-007, T-V5-008
- [x] 3.3 T-V5-062 — Ordering integration spec (state-based)
  - Files: spec/services/academy/lens/ordering_integration_spec.rb
  - Dep: T-V5-060, T-V5-061

## 4. Mission lifecycle services

- [x] 4.1 T-V5-070 — `Academy::Mission::Begin` idempotent mission opener
  - Files: app/services/academy/mission/begin.rb
  - Dep: T-V5-007, T-V5-060
- [x] 4.2 T-V5-071 — `Academy::Mission::AdvanceLens` step service
  - Files: app/services/academy/mission/advance_lens.rb
  - Dep: T-V5-060, T-V5-061, T-V5-073
- [x] 4.3 T-V5-072 — `Academy::Mission::Finalize` post-mission chain
  - Files: app/services/academy/mission/finalize.rb
  - Dep: T-V5-036, T-V5-075
- [x] 4.4 T-V5-073 — Wire `kid/academy/missions_controller` to v5 services
  - Files: app/controllers/kid/academy/missions_controller.rb
  - Dep: T-V5-070, T-V5-071, T-V5-090

## 5. UI lens stages

- [x] 5.1 T-V5-090 — Layout `_lens_stage.html.erb` and rewritten show
  - Files: app/views/kid/academy/missions/_lens_stage.html.erb, app/views/kid/academy/missions/show.html.erb
  - Dep: T-V5-033
- [x] 5.2 T-V5-091 — `Kid::Academy::LensProgressRingComponent`
  - Files: app/components/kid/academy/lens_progress_ring_component.rb
- [x] 5.3 T-V5-092 — `_lens_predict.html.erb` partial (scientific)
  - Files: app/views/kid/academy/missions/_lens_predict.html.erb
- [x] 5.4 T-V5-093 — `_lens_narrative.html.erb` partial
  - Files: app/views/kid/academy/missions/_lens_narrative.html.erb
- [x] 5.5 T-V5-094 — `_lens_compare.html.erb` partial
  - Files: app/views/kid/academy/missions/_lens_compare.html.erb
- [x] 5.6 T-V5-095 — `_lens_reconstruct.html.erb` partial
  - Files: app/views/kid/academy/missions/_lens_reconstruct.html.erb
- [x] 5.7 T-V5-096 — `_lens_pattern_hunt.html.erb` partial
  - Files: app/views/kid/academy/missions/_lens_pattern_hunt.html.erb
- [x] 5.8 T-V5-097 — `_lens_teach_back.html.erb` partial
  - Files: app/views/kid/academy/missions/_lens_teach_back.html.erb
- [x] 5.9 T-V5-098 — `_lens_historical.html.erb` partial
  - Files: app/views/kid/academy/missions/_lens_historical.html.erb
- [x] 5.10 T-V5-099 — `_lens_ethical_choice.html.erb` partial
  - Files: app/views/kid/academy/missions/_lens_ethical_choice.html.erb
- [x] 5.11 T-V5-100 — `lens_predict_controller.js` Stimulus controller
  - Files: app/assets/controllers/lens_predict_controller.js
- [x] 5.12 T-V5-101 — `lens_reconstruct_controller.js` Stimulus controller
  - Files: app/assets/controllers/lens_reconstruct_controller.js
- [x] 5.13 T-V5-102 — `lens_pattern_hunt_controller.js` Stimulus controller
  - Files: app/assets/controllers/lens_pattern_hunt_controller.js
- [x] 5.14 T-V5-103 — `lens_teach_back_controller.js` Stimulus controller
  - Files: app/assets/controllers/lens_teach_back_controller.js
- [x] 5.15 T-V5-104 — `lens_ethical_choice_controller.js` Stimulus controller
  - Files: app/assets/controllers/lens_ethical_choice_controller.js
- [x] 5.16 T-V5-105 — DESIGN.md chapter "Lentes"
  - Files: DESIGN.md
  - Dep: T-V5-090, T-V5-091, T-V5-092, T-V5-093, T-V5-094, T-V5-095, T-V5-096, T-V5-097, T-V5-098, T-V5-099, T-V5-100, T-V5-101, T-V5-102, T-V5-103, T-V5-104

## 6. Pokédex v5 ladder

- [x] 6.1 T-V5-075 — `Academy::Pokedex::Advance` revised L1/L2/L3 ladder
  - Files: app/services/academy/pokedex/advance.rb
  - Dep: T-V5-007
- [x] 6.2 T-V5-076 — Rake `academy:pokedex:reladder`
  - Files: lib/tasks/academy_pokedex.rake
  - Dep: T-V5-075, T-V5-115
- [x] 6.3 T-V5-077 — Pokédex Atlas labels/counters for v5
  - Files: app/views/kid/academy/atlas/_concept_chip.html.erb, app/views/kid/academy/atlas/index.html.erb
  - Dep: T-V5-075

## 7. Content migration v4 to v5

- [x] 7.1 T-V5-110 — Rake `academy:v5:migrate_missions`
  - Files: lib/tasks/academy_v5.rake
  - Dep: T-V5-004
- [x] 7.2 T-V5-111 — Archive v4 chat sessions (`active: false`)
  - Files: db/migrate/20260520000010_add_active_to_academy_sessions.rb, app/services/academy/sessions/archive_v4.rb
- [x] 7.3 T-V5-112 — Keep `academy_practice_wagers` as scientific lens payload
  - Files: docs/academy-v2.md
- [x] 7.4 T-V5-113 — Keep `academy_learner_story_paths` as narrative state
  - Files: docs/academy-v2.md
- [x] 7.5 T-V5-114 — Keep `virtue_sightings` + `transfer_detections`
  - Files: app/jobs/academy/transfer/detect_job.rb
  - Dep: T-V5-007
- [x] 7.6 T-V5-115 — Backfill `learner_lens_visits` from session history
  - Files: lib/tasks/academy_v5.rake
  - Dep: T-V5-007, T-V5-111

## 8. Eval suite + observability

- [x] 8.1 T-V5-080 — Eval `scientific` lens
  - Files: spec/services/academy/lens/generators/scientific_eval_spec.rb
  - Dep: T-V5-051
- [x] 8.2 T-V5-081 — Eval `narrative` lens
  - Files: spec/services/academy/lens/generators/narrative_eval_spec.rb
- [x] 8.3 T-V5-082 — Eval `ethical` lens
  - Files: spec/services/academy/lens/generators/ethical_eval_spec.rb
- [x] 8.4 T-V5-083 — Eval `statistical` lens
  - Files: spec/services/academy/lens/generators/statistical_eval_spec.rb
- [x] 8.5 T-V5-084 — Eval `engineering` lens
  - Files: spec/services/academy/lens/generators/engineering_eval_spec.rb
- [x] 8.6 T-V5-085 — Eval `historical` lens
  - Files: spec/services/academy/lens/generators/historical_eval_spec.rb
- [x] 8.7 T-V5-086 — Eval `first_person` lens
  - Files: spec/services/academy/lens/generators/first_person_eval_spec.rb
- [x] 8.8 T-V5-087 — Eval `analogy_bridge` lens
  - Files: spec/services/academy/lens/generators/analogy_bridge_eval_spec.rb
- [x] 8.9 T-V5-088 — Integration eval — full mission journey
  - Files: spec/services/academy/mission/full_journey_eval_spec.rb
  - Dep: T-V5-072, T-V5-075
- [x] 8.10 T-V5-089 — Quality dashboard for lens metrics
  - Files: app/controllers/parent/academy/quality_metrics_controller.rb
- [x] 8.11 T-V5-089b — `make eval-v5` Makefile target
  - Files: Makefile, config/ci.rb

## 9. Parent surfaces

- [x] 9.1 T-V5-120 — Parent digest revamp — `Digests::Compose` prompt v5
  - Files: app/services/academy/digests/compose.rb
  - Dep: T-V5-007
- [x] 9.2 T-V5-121 — Parent dashboard "Últimas missões e ângulos"
  - Files: app/controllers/parent/academy/journeys_controller.rb
  - Dep: T-V5-007

## 10. Admin / CMS

- [x] 10.1 T-V5-130 — Admin override editor for generated lenses
  - Files: app/controllers/admin/academy/lenses_controller.rb
  - Dep: T-V5-006
- [x] 10.2 T-V5-131 — "Regenerate lens" button in admin
  - Files: app/controllers/admin/academy/lenses_controller.rb
- [x] 10.3 T-V5-132 — Quality flagging for lens_cache rows
  - Files: db/migrate/20260520000020_add_quality_flagged_to_lens_cache.rb, app/controllers/admin/academy/lenses_controller.rb
  - Dep: T-V5-006, T-V5-089
