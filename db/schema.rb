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

ActiveRecord::Schema[8.1].define(version: 2026_04_19_203602) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activity_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "log_type"
    t.integer "points"
    t.bigint "profile_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["profile_id", "created_at"], name: "index_activity_logs_on_profile_id_and_created_at"
    t.index ["profile_id"], name: "index_activity_logs_on_profile_id"
  end

  create_table "families", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "global_tasks", force: :cascade do |t|
    t.integer "category"
    t.datetime "created_at", null: false
    t.string "days_of_week", default: [], array: true
    t.text "description"
    t.bigint "family_id", null: false
    t.integer "frequency"
    t.string "icon"
    t.integer "points"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_global_tasks_on_family_id"
  end

  create_table "profile_tasks", force: :cascade do |t|
    t.date "assigned_date"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "global_task_id", null: false
    t.bigint "profile_id", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["global_task_id"], name: "index_profile_tasks_on_global_task_id"
    t.index ["profile_id", "assigned_date"], name: "index_profile_tasks_on_profile_id_and_assigned_date"
    t.index ["profile_id", "status"], name: "index_profile_tasks_on_profile_id_and_status"
    t.index ["profile_id"], name: "index_profile_tasks_on_profile_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.string "avatar"
    t.datetime "created_at", null: false
    t.bigint "family_id", null: false
    t.string "name"
    t.integer "points", default: 0
    t.integer "role"
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_profiles_on_family_id"
  end

  create_table "redemptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "points"
    t.bigint "profile_id", null: false
    t.bigint "reward_id", null: false
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["profile_id"], name: "index_redemptions_on_profile_id"
    t.index ["reward_id"], name: "index_redemptions_on_reward_id"
  end

  create_table "rewards", force: :cascade do |t|
    t.integer "cost"
    t.datetime "created_at", null: false
    t.bigint "family_id", null: false
    t.string "icon"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_rewards_on_family_id"
  end

  add_foreign_key "activity_logs", "profiles"
  add_foreign_key "global_tasks", "families"
  add_foreign_key "profile_tasks", "global_tasks"
  add_foreign_key "profile_tasks", "profiles"
  add_foreign_key "profiles", "families"
  add_foreign_key "redemptions", "profiles"
  add_foreign_key "redemptions", "rewards"
  add_foreign_key "rewards", "families"
end
