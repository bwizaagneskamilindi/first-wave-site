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

ActiveRecord::Schema[8.1].define(version: 2026_10_10_174633) do
  create_table "payments", force: :cascade do |t|
    t.integer "registration_id", null: false
    t.string "reference_id", null: false
    t.string "payer_phone", null: false
    t.integer "amount", null: false
    t.string "currency", null: false
    t.string "status", default: "pending", null: false
    t.string "provider_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reference_id"], name: "index_payments_on_reference_id", unique: true
    t.index ["registration_id"], name: "index_payments_on_registration_id"
  end

  create_table "registrations", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "phone", null: false
    t.string "programme", null: false
    t.string "email"
    t.string "coming_with"
    t.json "interests", default: [], null: false
    t.integer "price", null: false
    t.boolean "early_bird", default: false, null: false
    t.string "status", default: "pending", null: false
    t.string "ticket_code", null: false
    t.datetime "checked_in_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "momo_transaction_id"
    t.datetime "payment_submitted_at"
    t.string "payment_method"
    t.string "confirmed_by"
    t.string "checked_in_by"
    t.index ["momo_transaction_id"], name: "index_registrations_on_momo_transaction_id", unique: true
    t.index ["phone"], name: "index_registrations_on_phone", unique: true
    t.index ["ticket_code"], name: "index_registrations_on_ticket_code", unique: true
  end

  add_foreign_key "payments", "registrations"
end
