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

ActiveRecord::Schema[8.0].define(version: 2025_06_02_115944) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "tickets", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "assigned_user_id"
    t.date "due_date"
    t.integer "status_id", default: 0
    t.integer "progress", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "mail"
    t.boolean "send_due_date_reminder", default: true
    t.integer "due_date_reminder_interval", default: 0
    t.integer "due_date_reminder_offset", default: 0
    t.time "due_date_reminder_time", default: "2000-01-01 09:00:00"
    t.string "time_zone", default: "Europe/Vienna"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
