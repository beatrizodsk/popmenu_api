require 'test_helper'

class MenuItemTest < ActiveSupport::TestCase
  test 'should be valid with valid attributes' do
    menu_item = build(:menu_item)
    assert menu_item.valid?
  end

  test 'name should be present' do
    menu_item = build(:menu_item, name: '   ')
    assert_not menu_item.valid?
  end

  test 'name should not be nil' do
    menu_item = build(:menu_item, name: nil)
    assert_not menu_item.valid?
  end

  test 'name should not be empty' do
    menu_item = build(:menu_item, name: '')
    assert_not menu_item.valid?
  end

  test 'price should be present' do
    menu_item = build(:menu_item, price: nil)
    assert_not menu_item.valid?
  end

  test 'price should not be empty' do
    menu_item = build(:menu_item, price: '')
    assert_not menu_item.valid?
  end

  test 'price should be a number' do
    menu_item = build(:menu_item, price: 'not a number')
    assert_not menu_item.valid?
  end

  test 'price should be greater than 0' do
    menu_item = build(:menu_item, price: 0)
    assert_not menu_item.valid?
  end

  test 'price should be greater than 0 (negative)' do
    menu_item = build(:menu_item, price: -5.99)
    assert_not menu_item.valid?
  end

  test 'price should accept decimal numbers' do
    menu_item = build(:menu_item, price: 9.99)
    assert menu_item.valid?
  end

  test 'price should accept integer numbers' do
    menu_item = build(:menu_item, price: 10)
    assert menu_item.valid?
  end

  test 'should provide validation error messages' do
    menu_item = build(:menu_item, :invalid)
    assert_not menu_item.valid?
    assert_includes menu_item.errors[:name], "can't be blank"
    assert_includes menu_item.errors[:price], 'must be greater than 0'
  end

  test 'should have and belong to many menus' do
    menu_item = create(:menu_item, :with_menus, menus_count: 2)
    assert_respond_to menu_item, :menus
    assert_equal 2, menu_item.menus.count
  end

  test 'should allow same menu item name across different menus' do
    menu1 = create(:menu, name: 'Menu 1')
    menu2 = create(:menu, name: 'Menu 2')

    menu_item1 = create(:menu_item, name: 'Pizza Margherita')
    menu_item2 = create(:menu_item, name: 'Pizza Margherita')

    menu1.menu_items << menu_item1
    menu2.menu_items << menu_item2

    assert menu_item1.valid?
    assert menu_item2.valid?
    assert_equal 'Pizza Margherita', menu_item1.name
    assert_equal 'Pizza Margherita', menu_item2.name
  end

  test 'should allow same menu item in multiple menus' do
    menu1 = create(:menu, name: 'Menu 1')
    menu2 = create(:menu, name: 'Menu 2')
    menu_item = create(:menu_item, name: 'Pizza Margherita')

    menu1.menu_items << menu_item
    menu2.menu_items << menu_item

    assert_equal 2, menu_item.menus.count
    assert_includes menu_item.menus, menu1
    assert_includes menu_item.menus, menu2
  end

  test 'should not affect menus when destroyed' do
    menu1 = create(:menu, name: 'Menu 1')
    menu2 = create(:menu, name: 'Menu 2')
    menu_item = create(:menu_item, name: 'Pizza Margherita')

    menu1.menu_items << menu_item
    menu2.menu_items << menu_item

    menu1_id = menu1.id
    menu2_id = menu2.id
    item_id = menu_item.id

    menu_item.destroy

    assert Menu.find(menu1_id)
    assert Menu.find(menu2_id)
    assert_raises(ActiveRecord::RecordNotFound) { MenuItem.find(item_id) }
    assert_equal 0, menu1.menu_items.count
    assert_equal 0, menu2.menu_items.count
  end
end
