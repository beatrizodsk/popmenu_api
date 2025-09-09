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

  test 'should belong to menu' do
    menu_item = create(:menu_item)
    assert_respond_to menu_item, :menu
    assert_not_nil menu_item.menu
  end

  test 'should require menu' do
    menu_item = build(:menu_item, :without_menu)
    assert_not menu_item.valid?
  end

  test 'should not be valid with non-existent menu' do
    menu_item = build(:menu_item, menu_id: 99_999)
    assert_not menu_item.valid?
  end

  test 'should not affect menu when destroyed' do
    menu_item = create(:menu_item)
    menu = menu_item.menu
    menu_id = menu.id
    item_id = menu_item.id

    menu_item.destroy

    assert Menu.find(menu_id)
    assert_raises(ActiveRecord::RecordNotFound) { MenuItem.find(item_id) }
    assert_equal 0, menu.menu_items.count
  end
end
