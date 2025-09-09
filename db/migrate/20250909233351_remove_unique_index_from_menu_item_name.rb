class RemoveUniqueIndexFromMenuItemName < ActiveRecord::Migration[7.1]
  def change
    remove_index :menu_items, :name
  end
end
