class RemoveMenuIdFromMenuItems < ActiveRecord::Migration[7.1]
  def change
    remove_reference :menu_items, :menu, null: false, foreign_key: true
  end
end
