# frozen_string_literal: true

# Consolidated initial schema migration.
#
# All prior migrations were squashed on 2026-05-20 because their original
# chronological order broke fresh deploys (some 2026-05-16 migrations
# touched tables only created on 2026-05-17). This single migration
# mirrors db/schema.rb exactly; new changes should be added as new
# migrations on top of this one.
class InitialSchema < ActiveRecord::Migration[8.1]
  def change
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"

  create_table "academy_concept_edges", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "edge_type", default: "relates_to", null: false, comment: "v4 typed edge — see migration header"
    t.bigint "from_concept_id", null: false
    t.integer "kind", default: 0, null: false, comment: "0=echoes (symmetric), 1=depends_on, 2=leads_to"
    t.bigint "to_concept_id", null: false
    t.datetime "updated_at", null: false
    t.index ["edge_type"], name: "idx_academy_concept_edges_edge_type"
    t.index ["from_concept_id", "to_concept_id", "kind"], name: "idx_academy_concept_edges_unique", unique: true
    t.index ["from_concept_id"], name: "index_academy_concept_edges_on_from_concept_id"
    t.index ["to_concept_id"], name: "index_academy_concept_edges_on_to_concept_id"
  end

  create_table "academy_concepts", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category", null: false, comment: "cognitivo | cientifico | social | financeiro | saude | virtude | tecnologia"
    t.text "common_confusion", comment: "Typical 7-12yo misread of this concept — feeds micro_check distractors"
    t.datetime "created_at", null: false
    t.text "definition", comment: "Plain-language 1-2 line description"
    t.text "forbidden_terms", default: [], null: false, comment: "Words this concept must never use (e.g. 'prazer' for dopamina)", array: true
    t.string "name", null: false
    t.string "pokedex_color_key", comment: "Design token name (e.g. 'pokedex-mind', 'pokedex-body')"
    t.string "pokedex_silhouette_key", comment: "Asset name in app/assets/images/academy/pokedex/ (svg)"
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.text "the_essence", comment: "Curator's one-sentence north star — what every lens must point to"
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_academy_concepts_on_category"
    t.index ["slug"], name: "index_academy_concepts_on_slug", unique: true
  end

  create_table "academy_discovery_cards", force: :cascade do |t|
    t.text "application", comment: "1-sentence concrete application"
    t.text "central_insight", comment: "Copied snapshot of mission insight at mint time"
    t.datetime "created_at", null: false
    t.string "headline", limit: 180, null: false, comment: "1-line sacada compressed"
    t.string "illustration_key", comment: "Icon/illustration to render"
    t.string "kind", default: "mission_card", null: false, comment: "mission_card | trail_theory | virtue_sighting"
    t.bigint "learner_id", null: false
    t.datetime "minted_at", null: false
    t.bigint "mission_id", null: false
    t.string "source", comment: "Author/tradition (optional, when applicable)"
    t.datetime "updated_at", null: false
    t.index ["learner_id", "kind"], name: "idx_academy_discovery_cards_learner_kind"
    t.index ["learner_id", "minted_at"], name: "idx_academy_cards_learner_time"
    t.index ["learner_id", "mission_id"], name: "idx_academy_cards_unique", unique: true
    t.index ["mission_id"], name: "index_academy_discovery_cards_on_mission_id"
  end

  create_table "academy_guide_conversations", force: :cascade do |t|
    t.datetime "closed_at", comment: "Set when quota cap is hit or session expires"
    t.datetime "created_at", null: false
    t.text "flag_reasons", default: [], null: false, array: true
    t.boolean "flagged", default: false, null: false
    t.bigint "learner_id", null: false, comment: "Learner value-object id (no FK — module isolation)"
    t.integer "message_count", default: 0, null: false
    t.bigint "mission_id", null: false
    t.string "prompt_version", default: "guide-persona@v1", null: false, comment: "Frozen at conversation start so future persona iterations don't reinterpret history"
    t.datetime "started_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flagged", "started_at"], name: "idx_academy_guide_conv_flagged", order: { started_at: :desc }, where: "(flagged = true)"
    t.index ["learner_id", "mission_id", "started_at"], name: "idx_academy_guide_conv_learner_mission_started", order: { started_at: :desc }
    t.index ["mission_id"], name: "index_academy_guide_conversations_on_mission_id"
  end

  create_table "academy_guide_messages", force: :cascade do |t|
    t.text "content", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.boolean "flagged", default: false, null: false
    t.integer "role", null: false, comment: "0 user · 1 guide · 2 system_note"
    t.integer "tokens_in"
    t.integer "tokens_out"
    t.index ["conversation_id", "created_at"], name: "idx_academy_guide_msg_conv_created"
  end

  create_table "academy_learner_concepts", force: :cascade do |t|
    t.bigint "concept_id", null: false
    t.datetime "created_at", null: false
    t.datetime "evolved_to_2_at"
    t.datetime "evolved_to_3_at"
    t.datetime "first_seen_at"
    t.datetime "last_seen_at"
    t.bigint "learner_id", null: false, comment: "Learner value-object id (no FK by design — module isolation)"
    t.integer "level", default: 0, null: false, comment: "0..3 (silhouette → mastered)"
    t.integer "seen_in_subjects_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["concept_id"], name: "index_academy_learner_concepts_on_concept_id"
    t.index ["learner_id", "concept_id"], name: "idx_academy_learner_concepts_unique", unique: true
    t.index ["learner_id", "level"], name: "idx_academy_learner_concepts_level"
  end

  create_table "academy_learner_lens_visits", force: :cascade do |t|
    t.string "chooser_version", comment: "Which version of ChooseNext picked this lens"
    t.datetime "closed_at"
    t.bigint "concept_id", null: false
    t.datetime "created_at", null: false
    t.bigint "learner_id", null: false
    t.boolean "legacy", default: false, null: false
    t.bigint "lens_cache_id"
    t.string "lens_type", null: false
    t.bigint "mission_progress_id", null: false
    t.datetime "opened_at", null: false
    t.integer "ordering_position", null: false, comment: "1-based position within mission attempt"
    t.string "outcome", comment: "completed | abandoned | skipped_by_system"
    t.jsonb "signal_payload", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["learner_id", "concept_id", "lens_type"], name: "idx_academy_lens_visits_learner_concept_lens"
    t.index ["learner_id", "opened_at"], name: "idx_academy_lens_visits_learner_opened"
    t.index ["mission_progress_id", "ordering_position"], name: "idx_academy_lens_visits_position", unique: true
  end

  create_table "academy_learner_signals", force: :cascade do |t|
    t.integer "affinity_score", default: 0, null: false, comment: "Cumulative weighted signal: completions + correct checkpoints + done challenges"
    t.integer "completion_count", default: 0, null: false
    t.integer "correct_checkpoints", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "last_session_at"
    t.bigint "learner_id", null: false
    t.bigint "subject_id", null: false
    t.datetime "updated_at", null: false
    t.integer "wrong_checkpoints", default: 0, null: false
    t.index ["learner_id", "subject_id"], name: "idx_academy_signals_learner_subject", unique: true
    t.index ["subject_id"], name: "index_academy_learner_signals_on_subject_id"
  end

  create_table "academy_learner_story_paths", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "learner_id", null: false, comment: "Learner value-object id (no FK)"
    t.bigint "mission_id", null: false
    t.jsonb "scene_sequence", default: [], null: false, comment: "Ordered: [{scene_id, choice_label, at}]"
    t.string "terminal_scene_id", comment: "Final scene reached, when mission ends"
    t.datetime "updated_at", null: false
    t.index ["learner_id", "mission_id"], name: "idx_academy_learner_story_paths_learner_mission"
    t.index ["mission_id"], name: "index_academy_learner_story_paths_on_mission_id"
    t.index ["terminal_scene_id"], name: "idx_academy_learner_story_paths_terminal"
  end

  create_table "academy_lens_cache", force: :cascade do |t|
    t.string "age_band", default: "kid", null: false
    t.bigint "concept_id", null: false
    t.datetime "created_at", null: false
    t.datetime "generated_at", null: false
    t.string "interest_key"
    t.string "lens_type", null: false
    t.string "locale", default: "pt-BR", null: false
    t.jsonb "payload", default: {}, null: false
    t.boolean "quality_flagged", default: false, null: false
    t.string "source", default: "curated", null: false
    t.datetime "updated_at", null: false
    t.index "concept_id, lens_type, age_band, locale, COALESCE(interest_key, ''::character varying)", name: "idx_academy_lens_cache_unique", unique: true
    t.index ["concept_id", "lens_type", "source"], name: "idx_academy_lens_cache_source_lookup"
    t.index ["interest_key"], name: "idx_academy_lens_cache_interest_key", where: "(interest_key IS NOT NULL)"
    t.index ["lens_type"], name: "index_academy_lens_cache_on_lens_type"
    t.index ["quality_flagged"], name: "idx_academy_lens_cache_quality_flagged", where: "(quality_flagged = true)"
  end

  create_table "academy_lens_signals", force: :cascade do |t|
    t.bigint "concept_id", null: false
    t.datetime "created_at", null: false
    t.bigint "learner_id", null: false
    t.string "lens_type", null: false
    t.bigint "lens_visit_id"
    t.bigint "mission_progress_id", null: false
    t.decimal "numeric_value", precision: 12, scale: 4, comment: "Seconds, scores, etc; nullable"
    t.datetime "recorded_at", null: false
    t.string "signal_type", null: false, comment: "time_on_lens | micro_check_correct | micro_check_wrong | abandoned | self_report_easy | self_report_hard | transfer_hint"
    t.datetime "updated_at", null: false
    t.index ["learner_id", "concept_id", "lens_type", "recorded_at"], name: "idx_academy_lens_signals_learner_concept_lens_time"
    t.index ["learner_id", "signal_type", "recorded_at"], name: "idx_academy_lens_signals_learner_type_time"
    t.index ["mission_progress_id", "recorded_at"], name: "idx_academy_lens_signals_progress_time"
  end

  create_table "academy_lightning_round_runs", force: :cascade do |t|
    t.jsonb "concept_ids", default: [], null: false
    t.integer "correct_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "elapsed_seconds"
    t.bigint "learner_id", null: false
    t.string "tier", null: false
    t.integer "total_questions", null: false
    t.datetime "updated_at", null: false
    t.index ["learner_id", "created_at"], name: "idx_academy_lightning_runs_by_learner_recency"
  end

  create_table "academy_messages", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "role", default: 0, null: false
    t.bigint "session_id", null: false
    t.integer "tokens"
    t.datetime "updated_at", null: false
    t.index ["session_id", "created_at"], name: "idx_academy_messages_session_time"
    t.index ["session_id"], name: "idx_academy_messages_session"
  end

  create_table "academy_mission_progresses", force: :cascade do |t|
    t.datetime "completed_at"
    t.integer "correct_checkpoints", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "current_session_index", default: 0, null: false
    t.bigint "learner_id", null: false
    t.bigint "mission_id", null: false
    t.datetime "skills_awarded_at", comment: "Set the first time Skills::Award(:completed) runs for this progress; further calls are no-ops"
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.integer "total_checkpoints", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["learner_id", "mission_id"], name: "idx_academy_progress_learner_mission", unique: true
    t.index ["learner_id", "status"], name: "idx_academy_progress_learner_status"
    t.index ["mission_id"], name: "index_academy_mission_progresses_on_mission_id"
  end

  create_table "academy_missions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "angle", comment: "Specific unique angle for this mission"
    t.string "central_insight", limit: 240, comment: "The 'se X, então Y' takeaway the kid should keep"
    t.string "challenge_observable", comment: "What the kid should notice after doing it"
    t.text "challenge_prompt", comment: "Mini-desafio comportamental that anchors the lesson"
    t.string "challenge_when", comment: "When to do the challenge: hoje | esta-semana"
    t.bigint "concept_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "curiosity_facts", default: [], null: false
    t.string "framework", comment: "Didactic frame: socratic | story | metaphor | case | thought_experiment | paradox | historical_scene"
    t.string "hook", comment: "Short mysterious teaser to entice the kid"
    t.string "illustration_key", comment: "Icon/illustration slug the discovery card uses"
    t.text "learning_objective", null: false
    t.integer "order_in_subject", default: 0, null: false
    t.integer "points_reward", default: 25, null: false
    t.integer "position_in_trail"
    t.text "sacada", comment: "The 1-line counter-intuitive insight (the 'pílula' itself)"
    t.string "slug", null: false
    t.string "source", comment: "Author(s)/tradition/study the pílula distills (e.g. 'Carnegie', 'Marco Aurélio', 'Provérbios')"
    t.bigint "subject_id", null: false
    t.string "title", null: false
    t.bigint "trail_id"
    t.datetime "updated_at", null: false
    t.index ["concept_id"], name: "index_academy_missions_on_concept_id"
    t.index ["framework"], name: "index_academy_missions_on_framework"
    t.index ["source"], name: "index_academy_missions_on_source"
    t.index ["subject_id", "order_in_subject"], name: "index_academy_missions_on_subject_id_and_order_in_subject"
    t.index ["subject_id", "slug"], name: "index_academy_missions_on_subject_id_and_slug", unique: true
    t.index ["subject_id"], name: "index_academy_missions_on_subject_id"
    t.index ["trail_id"], name: "index_academy_missions_on_trail_id"
  end

  create_table "academy_pill_views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "learner_id", null: false
    t.bigint "lens_cache_id", null: false
    t.integer "micro_check_choice"
    t.boolean "micro_check_correct"
    t.boolean "shared_with_parent", default: false, null: false
    t.string "status", default: "served", null: false
    t.datetime "updated_at", null: false
    t.datetime "viewed_at"
    t.index ["learner_id", "created_at"], name: "idx_academy_pill_views_by_learner_recency"
    t.index ["learner_id", "lens_cache_id"], name: "idx_academy_pill_views_unique_per_learner", unique: true
  end

  create_table "academy_practice_wagers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "guide_bet_count", null: false, comment: "The Guide's numeric wager (extracted from LLM payload)"
    t.integer "learner_actual_count", comment: "What the kid reports D+1 — nil until reported"
    t.bigint "learner_id", null: false, comment: "Learner value-object id (no FK)"
    t.text "learner_note", comment: "Optional short note from the kid alongside the count"
    t.bigint "mission_id", null: false
    t.datetime "observed_at"
    t.string "parent_observation", comment: "seen_match | seen_higher | seen_lower | skip"
    t.datetime "reported_at"
    t.datetime "updated_at", null: false
    t.index ["learner_id", "mission_id"], name: "idx_academy_practice_wagers_unique", unique: true
    t.index ["learner_id", "reported_at"], name: "idx_academy_practice_wagers_learner_reported"
    t.index ["mission_id"], name: "index_academy_practice_wagers_on_mission_id"
  end

  create_table "academy_secret_unlocks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "learner_id", null: false
    t.bigint "secret_id", null: false
    t.boolean "seen", default: false, null: false
    t.datetime "unlocked_at", null: false
    t.datetime "updated_at", null: false
    t.index ["learner_id", "secret_id"], name: "idx_academy_secret_unlocks_unique", unique: true
    t.index ["secret_id"], name: "index_academy_secret_unlocks_on_secret_id"
  end

  create_table "academy_secrets", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "kind", default: 0, null: false, comment: "0=cards_in_subject, 1=cards_total, 2=challenge_ratio"
    t.bigint "mission_id", comment: "Optional bonus pílula tied to this secret"
    t.integer "position", default: 0, null: false
    t.jsonb "rule", default: {}, null: false, comment: "e.g. { subject_slug: 'mente-forte', threshold: 5 }"
    t.string "slug", null: false
    t.text "teaser", comment: "Mysterious hint shown when locked"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["mission_id"], name: "index_academy_secrets_on_mission_id"
    t.index ["slug"], name: "index_academy_secrets_on_slug", unique: true
  end

  create_table "academy_sessions", force: :cascade do |t|
    t.jsonb "checkpoint_result", default: {}, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "mission_progress_id", null: false
    t.integer "session_index", null: false
    t.datetime "started_at"
    t.datetime "updated_at", null: false
    t.index ["mission_progress_id", "session_index"], name: "idx_academy_sessions_unique_idx", unique: true
    t.index ["mission_progress_id"], name: "idx_academy_sessions_progress"
  end

  create_table "academy_subjects", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "angle", comment: "Pedagogical angle the LLM should adopt"
    t.string "color", default: "var(--c-primary)"
    t.datetime "created_at", null: false
    t.string "icon", default: "sparkle"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.string "tagline"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_academy_subjects_on_slug", unique: true
  end

  create_table "academy_trails", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "arc_hook", comment: "One-line gancho for the whole trail arc"
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.bigint "subject_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_id", "position"], name: "idx_academy_trails_subject_position"
    t.index ["subject_id", "slug"], name: "idx_academy_trails_subject_slug", unique: true
    t.index ["subject_id"], name: "index_academy_trails_on_subject_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "decayed_at"
    t.integer "log_type"
    t.integer "points"
    t.bigint "profile_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["decayed_at"], name: "index_activity_logs_undecayed_earns", where: "((decayed_at IS NULL) AND (log_type = 0))"
    t.index ["profile_id", "created_at"], name: "index_activity_logs_on_profile_id_and_created_at"
    t.index ["profile_id", "log_type"], name: "index_activity_logs_on_profile_id_and_log_type"
    t.index ["profile_id"], name: "index_activity_logs_on_profile_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.bigint "family_id", null: false
    t.string "icon", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["family_id", "name"], name: "index_categories_on_family_id_and_name", unique: true
    t.index ["family_id", "position"], name: "index_categories_on_family_id_and_position"
    t.index ["family_id"], name: "index_categories_on_family_id"
  end

  create_table "families", force: :cascade do |t|
    t.boolean "allow_negative", default: false
    t.integer "auto_approve_threshold"
    t.datetime "created_at", null: false
    t.integer "day_start_hour", default: 0, null: false
    t.boolean "decay_enabled", default: false
    t.citext "email"
    t.date "last_reset_on"
    t.string "locale", default: "pt-BR"
    t.integer "max_debt", default: 100, null: false
    t.string "name"
    t.string "password_digest"
    t.boolean "require_photo", default: false
    t.string "timezone", default: "America/Sao_Paulo"
    t.datetime "updated_at", null: false
    t.integer "week_start", default: 1
    t.index ["email"], name: "index_families_on_email", unique: true
  end

  create_table "global_task_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "global_task_id", null: false
    t.bigint "profile_id", null: false
    t.datetime "updated_at", null: false
    t.index ["global_task_id", "profile_id"], name: "idx_global_task_assignments_unique", unique: true
    t.index ["global_task_id"], name: "index_global_task_assignments_on_global_task_id"
    t.index ["profile_id"], name: "index_global_task_assignments_on_profile_id"
  end

  create_table "global_tasks", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "category"
    t.datetime "created_at", null: false
    t.integer "day_of_month"
    t.string "days_of_week", default: [], array: true
    t.text "description"
    t.bigint "family_id", null: false
    t.boolean "featured", default: false, null: false
    t.integer "frequency"
    t.string "icon"
    t.integer "max_completions_per_period", default: 1, null: false
    t.integer "points"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["family_id", "featured"], name: "index_global_tasks_on_family_id_and_featured", where: "(featured = true)"
    t.index ["family_id"], name: "index_global_tasks_on_family_id"
    t.check_constraint "max_completions_per_period >= 1", name: "max_completions_positive"
  end

  create_table "profile_interests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "interest_key", null: false
    t.bigint "profile_id", null: false
    t.integer "rank", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["profile_id", "interest_key"], name: "idx_profile_interests_unique_per_profile", unique: true
    t.index ["profile_id", "rank"], name: "index_profile_interests_on_profile_id_and_rank"
    t.index ["profile_id"], name: "index_profile_interests_on_profile_id"
  end

  create_table "profile_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.bigint "family_id", null: false
    t.bigint "invited_by_id"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_profile_invitations_on_family_id"
    t.index ["token"], name: "index_profile_invitations_on_token", unique: true
  end

  create_table "profile_tasks", force: :cascade do |t|
    t.date "assigned_date"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "custom_category_id"
    t.text "custom_description"
    t.integer "custom_points"
    t.string "custom_title"
    t.bigint "global_task_id"
    t.bigint "profile_id", null: false
    t.integer "source", default: 0, null: false
    t.integer "status", default: 0
    t.text "submission_comment"
    t.datetime "updated_at", null: false
    t.index ["custom_category_id"], name: "index_profile_tasks_on_custom_category_id"
    t.index ["global_task_id"], name: "index_profile_tasks_on_global_task_id"
    t.index ["profile_id", "assigned_date"], name: "index_profile_tasks_on_profile_id_and_assigned_date"
    t.index ["profile_id", "status"], name: "index_profile_tasks_on_profile_id_and_status"
    t.index ["profile_id"], name: "index_profile_tasks_on_profile_id"
    t.index ["source"], name: "index_profile_tasks_on_source"
  end

  create_table "profiles", force: :cascade do |t|
    t.string "avatar"
    t.string "color"
    t.datetime "created_at", null: false
    t.citext "email"
    t.bigint "family_id", null: false
    t.string "name"
    t.string "pin_digest"
    t.integer "points", default: 0
    t.integer "role"
    t.datetime "updated_at", null: false
    t.bigint "wishlist_reward_id"
    t.index ["family_id", "role"], name: "index_profiles_on_family_id_and_role"
    t.index ["family_id"], name: "index_profiles_on_family_id"
    t.index ["wishlist_reward_id"], name: "index_profiles_on_wishlist_reward_id"
  end

  create_table "redemptions", force: :cascade do |t|
    t.boolean "collective", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "points"
    t.bigint "profile_id", null: false
    t.bigint "reward_id", null: false
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["profile_id", "status"], name: "index_redemptions_on_profile_id_and_status"
    t.index ["profile_id"], name: "index_redemptions_on_profile_id"
    t.index ["reward_id"], name: "index_redemptions_on_reward_id"
  end

  create_table "rewards", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.boolean "collective", default: false, null: false
    t.integer "cost"
    t.datetime "created_at", null: false
    t.bigint "family_id", null: false
    t.string "icon"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_rewards_on_category_id"
    t.index ["collective"], name: "index_rewards_on_collective"
    t.index ["family_id"], name: "index_rewards_on_family_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  add_foreign_key "academy_concept_edges", "academy_concepts", column: "from_concept_id"
  add_foreign_key "academy_concept_edges", "academy_concepts", column: "to_concept_id"
  add_foreign_key "academy_discovery_cards", "academy_missions", column: "mission_id"
  add_foreign_key "academy_guide_conversations", "academy_missions", column: "mission_id"
  add_foreign_key "academy_guide_messages", "academy_guide_conversations", column: "conversation_id"
  add_foreign_key "academy_learner_concepts", "academy_concepts", column: "concept_id"
  add_foreign_key "academy_learner_lens_visits", "academy_concepts", column: "concept_id"
  add_foreign_key "academy_learner_lens_visits", "academy_lens_cache", column: "lens_cache_id"
  add_foreign_key "academy_learner_lens_visits", "academy_mission_progresses", column: "mission_progress_id"
  add_foreign_key "academy_learner_signals", "academy_subjects", column: "subject_id"
  add_foreign_key "academy_learner_story_paths", "academy_missions", column: "mission_id"
  add_foreign_key "academy_lens_cache", "academy_concepts", column: "concept_id"
  add_foreign_key "academy_lens_signals", "academy_learner_lens_visits", column: "lens_visit_id"
  add_foreign_key "academy_lens_signals", "academy_mission_progresses", column: "mission_progress_id"
  add_foreign_key "academy_messages", "academy_sessions", column: "session_id"
  add_foreign_key "academy_mission_progresses", "academy_missions", column: "mission_id"
  add_foreign_key "academy_missions", "academy_concepts", column: "concept_id"
  add_foreign_key "academy_missions", "academy_subjects", column: "subject_id"
  add_foreign_key "academy_missions", "academy_trails", column: "trail_id"
  add_foreign_key "academy_pill_views", "academy_lens_cache", column: "lens_cache_id"
  add_foreign_key "academy_practice_wagers", "academy_missions", column: "mission_id"
  add_foreign_key "academy_secret_unlocks", "academy_secrets", column: "secret_id"
  add_foreign_key "academy_secrets", "academy_missions", column: "mission_id"
  add_foreign_key "academy_sessions", "academy_mission_progresses", column: "mission_progress_id"
  add_foreign_key "academy_trails", "academy_subjects", column: "subject_id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_logs", "profiles"
  add_foreign_key "categories", "families"
  add_foreign_key "global_task_assignments", "global_tasks", on_delete: :cascade
  add_foreign_key "global_task_assignments", "profiles", on_delete: :cascade
  add_foreign_key "global_tasks", "families"
  add_foreign_key "profile_interests", "profiles"
  add_foreign_key "profile_invitations", "families", on_delete: :cascade
  add_foreign_key "profile_invitations", "profiles", column: "invited_by_id", on_delete: :nullify
  add_foreign_key "profile_tasks", "categories", column: "custom_category_id", on_delete: :nullify
  add_foreign_key "profile_tasks", "global_tasks"
  add_foreign_key "profile_tasks", "profiles"
  add_foreign_key "profiles", "families"
  add_foreign_key "profiles", "rewards", column: "wishlist_reward_id", on_delete: :nullify
  add_foreign_key "redemptions", "profiles"
  add_foreign_key "redemptions", "rewards"
  add_foreign_key "rewards", "categories"
  add_foreign_key "rewards", "families"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  end
end
