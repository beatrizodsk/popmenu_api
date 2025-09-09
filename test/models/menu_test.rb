require 'test_helper'

class MenuTest < ActiveSupport::TestCase
  test 'name should be present' do
    menu = build(:menu, name: '   ')
    assert_not menu.valid?
  end

  test 'name should not be nil' do
    menu = build(:menu, name: nil)
    assert_not menu.valid?
  end

  test 'name should not be empty' do
    menu = build(:menu, name: '')
    assert_not menu.valid?
  end

  test 'name should allow duplicates' do
    menu = create(:menu)
    duplicate_menu = build(:menu, name: menu.name)
    assert duplicate_menu.valid?
  end

  test 'should have and belong to many menu items' do
    menu = create(:menu, :with_menu_items, menu_items_count: 5)
    assert_respond_to menu, :menu_items
    assert_equal 5, menu.menu_items.count
  end

  test 'should not destroy associated menu items when menu is destroyed' do
    menu = create(:menu)
    menu_item1 = create(:menu_item)
    menu_item2 = create(:menu_item)

    menu.menu_items << [menu_item1, menu_item2]

    assert_equal 2, menu.menu_items.count

    menu.destroy

    assert MenuItem.find(menu_item1.id)
    assert MenuItem.find(menu_item2.id)
  end

  test 'should be valid without menu items' do
    menu = create(:menu, :empty)
    assert menu.valid?
    assert_equal 0, menu.menu_items.count
  end

  test 'should handle validation errors when adding menu items' do
    menu = create(:menu)
    invalid_item = MenuItem.new(name: '', price: -1)

    assert_not invalid_item.valid?
    assert_not invalid_item.save
    assert_equal 0, menu.menu_items.count
  end

  test 'should handle transaction rollback when adding menu items' do
    menu = create(:menu)
    Menu.transaction do
      menu_item = MenuItem.create!(name: 'Transaction Item', price: 14.99)
      menu.menu_items << menu_item
      raise ActiveRecord::Rollback
    end

    assert_equal 0, menu.menu_items.count
  end
end
