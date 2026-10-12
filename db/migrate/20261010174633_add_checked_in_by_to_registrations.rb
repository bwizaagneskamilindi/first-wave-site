class AddCheckedInByToRegistrations < ActiveRecord::Migration[8.1]
  def change
    add_column :registrations, :checked_in_by, :string
  end
end
