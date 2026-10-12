class AddManualPaymentToRegistrations < ActiveRecord::Migration[8.1]
  def change
    add_column :registrations, :momo_transaction_id, :string
    add_index :registrations, :momo_transaction_id, unique: true
    add_column :registrations, :payment_submitted_at, :datetime
    add_column :registrations, :payment_method, :string
    add_column :registrations, :confirmed_by, :string
  end
end
