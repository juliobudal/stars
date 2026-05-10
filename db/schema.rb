# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_10_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"

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
    t.boolean "decay_enabled", default: false
    t.citext "email"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_logs", "profiles"
  add_foreign_key "categories", "families"
  add_foreign_key "global_task_assignments", "global_tasks", on_delete: :cascade
  add_foreign_key "global_task_assignments", "profiles", on_delete: :cascade
  add_foreign_key "global_tasks", "families"
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
