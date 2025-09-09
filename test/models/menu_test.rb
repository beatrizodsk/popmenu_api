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

  test 'name should not be unique' do
    menu = create(:menu)
    duplicate_menu = build(:menu, name: menu.name)
    assert duplicate_menu.valid?
  end

  test 'should have many menu items' do
    menu = create(:menu, :with_menu_items, menu_items_count: 5)
    assert_respond_to menu, :menu_items
    assert_equal 5, menu.menu_items.count
  end

  test 'should destroy associated menu items when menu is destroyed' do
    menu = create(:menu)
    menu_item1 = create(:menu_item, menu: menu)
    menu_item2 = create(:menu_item, menu: menu)

    assert_equal 2, menu.menu_items.count

    menu.destroy

    assert_raises(ActiveRecord::RecordNotFound) { menu_item1.reload }
    assert_raises(ActiveRecord::RecordNotFound) { menu_item2.reload }
  end

  test 'should be valid without menu items' do
    menu = create(:menu, :empty)
    assert menu.valid?
    assert_equal 0, menu.menu_items.count
  end

  test 'should handle validation errors in association' do
    menu = create(:menu)
    invalid_item = menu.menu_items.build(name: '', price: -1)

    assert_not invalid_item.valid?
    assert_not invalid_item.save
    assert_equal 0, menu.menu_items.count
  end

  test 'should handle transaction rollback in association' do
    menu = create(:menu)
    Menu.transaction do
      menu.menu_items.create!(name: 'Transaction Item', price: 14.99)
      raise ActiveRecord::Rollback
    end

    assert_equal 0, menu.menu_items.count
  end
end
