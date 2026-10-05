class CreateRegistrations < ActiveRecord::Migration[8.1]
  def change
  create_table :registrations do |t|
    t.string  :full_name,   null: false
    t.string  :phone,       null: false   # stored as 2507XXXXXXXX
    t.string  :programme,   null: false
    t.string  :email
    t.string  :coming_with
    t.json    :interests,   null: false, default: []

    t.integer :price,       null: false   # RWF, whole numbers
    t.boolean :early_bird,  null: false, default: false
    t.string  :status,      null: false, default: "pending"  # pending / paid / cancelled
    t.string  :ticket_code, null: false
    t.datetime :checked_in_at

    t.timestamps
  end

  add_index :registrations, :phone, unique: true
  add_index :registrations, :ticket_code, unique: true
  end
end
