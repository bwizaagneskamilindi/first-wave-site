class CreatePayments < ActiveRecord::Migration[8.1]
  def change
  create_table :payments do |t|
    t.references :registration, null: false, foreign_key: true
    t.string  :reference_id,     null: false   # unique ID we send to MTN
    t.string  :payer_phone,      null: false   # MTN number that pays, e.g. 250788123456
    t.integer :amount,           null: false
    t.string  :currency,         null: false
    t.string  :status,           null: false, default: "pending"  # pending / successful / failed
    t.string  :provider_message  # MTN's reason if it fails

    t.timestamps
  end

  add_index :payments, :reference_id, unique: true
  end
end
