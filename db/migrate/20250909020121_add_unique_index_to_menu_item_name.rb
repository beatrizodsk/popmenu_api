class AddUniqueIndexToMenuItemName < ActiveRecord::Migration[7.1]
  def change
    add_index :menu_items, :name, unique: true
  end
end
