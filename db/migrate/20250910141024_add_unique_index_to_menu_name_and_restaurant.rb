class AddUniqueIndexToMenuNameAndRestaurant < ActiveRecord::Migration[7.1]
  def change
    add_index :menus, [:name, :restaurant_id], unique: true
  end
end
