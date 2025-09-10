class AddUniqueIndexToRestaurantName < ActiveRecord::Migration[7.1]
  def change
    add_index :restaurants, :name, unique: true
  end
end
