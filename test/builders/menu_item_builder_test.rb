require 'test_helper'

class MenuItemBuilderTest < ActiveSupport::TestCase
  def setup
    @logger = ImportLogger.new
    @menu = create(:menu)
  end

  test 'should create new menu item when none exists' do
    item_data = { 'name' => 'Burger', 'price' => 10.50 }
    builder = MenuItemBuilder.new(item_data, @logger)

    assert_difference('MenuItem.count', 1) do
      menu_item = builder.call
      assert_equal 'Burger', menu_item.name
      assert_equal 10.50, menu_item.price
    end
  end

  test 'should find existing menu item when exact match exists' do
    create(:menu_item, name: 'Burger', price: 10.50)
    item_data = { 'name' => 'Burger', 'price' => 10.50 }
    builder = MenuItemBuilder.new(item_data, @logger)

    assert_no_difference('MenuItem.count') do
      found_item = builder.call
      assert_equal 'Burger', found_item.name
      assert_equal 10.50, found_item.price
    end
  end

  test 'should find menu item case-insensitive' do
    create(:menu_item, name: 'Burger', price: 10.50)
    item_data = { 'name' => 'burger', 'price' => 10.50 }
    builder = MenuItemBuilder.new(item_data, @logger)

    assert_no_difference('MenuItem.count') do
      found_item = builder.call
      assert_equal 'Burger', found_item.name
      assert_equal 10.50, found_item.price
    end
  end

  test 'should find menu item ignoring extra whitespace' do
    create(:menu_item, name: 'French Fries', price: 5.00)
    item_data = { 'name' => '  french fries  ', 'price' => 5.00 }
    builder = MenuItemBuilder.new(item_data, @logger)

    assert_no_difference('MenuItem.count') do
      found_item = builder.call
      assert_equal 'French Fries', found_item.name
      assert_equal 5.00, found_item.price
    end
  end

  test 'should reuse existing menu item for same name regardless of price' do
    existing_item = create(:menu_item, name: 'Burger', price: 9.00)
    item_data = { 'name' => 'burger', 'price' => 15.00 }
    builder = MenuItemBuilder.new(item_data, @logger)

    assert_no_difference('MenuItem.count') do
      menu_item = builder.call
      assert_equal existing_item.id, menu_item.id
      assert_equal 'Burger', menu_item.name
      assert_equal 9.00, menu_item.price # Original price is preserved
    end
  end

  test 'should not create duplicate association' do
    menu_item = create(:menu_item, name: 'Pizza', price: 12.00)
    builder = MenuItemBuilder.new({}, @logger)

    # Primeira associação
    builder.associate_with_menu(menu_item, @menu)
    assert_equal 1, @menu.menu_items.count

    # Tentativa de duplicar associação
    builder.associate_with_menu(menu_item, @menu)
    assert_equal 1, @menu.menu_items.count # não deve aumentar
  end

  test 'should log when association already exists' do
    menu_item = create(:menu_item, name: 'Pizza', price: 12.00)
    @menu.menu_items << menu_item
    builder = MenuItemBuilder.new({}, @logger)

    builder.associate_with_menu(menu_item, @menu)

    logs = @logger.summary[:logs]
    assert(logs.any? { |log| log[:message].include?('already associated') })
  end

  test 'should log appropriate messages for existing menu item' do
    create(:menu_item, name: 'Burger', price: 10.50)
    item_data = { 'name' => 'burger', 'price' => 10.50 }
    builder = MenuItemBuilder.new(item_data, @logger)

    builder.call

    logs = @logger.summary[:logs]
    assert(logs.any? { |log| log[:message].include?('Menu item already exists') })
  end

  test 'should log appropriate messages for new menu item' do
    item_data = { 'name' => 'New Item', 'price' => 8.00 }
    builder = MenuItemBuilder.new(item_data, @logger)

    builder.call

    logs = @logger.summary[:logs]
    assert(logs.any? { |log| log[:message].include?('Created menu item') })
  end

  test 'should handle menu item creation errors gracefully' do
    item_data = { 'name' => '', 'price' => -1 } # invalid data
    builder = MenuItemBuilder.new(item_data, @logger)

    assert_raises(ActiveRecord::RecordInvalid) do
      builder.call
    end

    logs = @logger.summary[:logs]
    assert(logs.any? { |log| log[:message].include?('Failed to create menu item') })
  end

  test 'should preserve original menu item name when finding existing' do
    existing_item = create(:menu_item, name: 'Burger', price: 10.50)
    item_data = { 'name' => 'burger', 'price' => 10.50 }
    builder = MenuItemBuilder.new(item_data, @logger)

    found_item = builder.call
    assert_equal 'Burger', found_item.name
    assert_equal existing_item.id, found_item.id
  end

  test 'should handle mixed case variations' do
    create(:menu_item, name: 'French Fries', price: 5.00)
    item_data = { 'name' => 'FRENCH FRIES', 'price' => 5.00 }
    builder = MenuItemBuilder.new(item_data, @logger)

    assert_no_difference('MenuItem.count') do
      found_item = builder.call
      assert_equal 'French Fries', found_item.name
    end
  end

  test 'should create menu item with trimmed name' do
    item_data = { 'name' => '  New Item  ', 'price' => 8.00 }
    builder = MenuItemBuilder.new(item_data, @logger)

    assert_difference('MenuItem.count', 1) do
      menu_item = builder.call
      assert_equal 'New Item', menu_item.name # whitespace trimmed
    end
  end

  test 'should handle nil name gracefully' do
    item_data = { 'name' => nil, 'price' => 10.00 }
    builder = MenuItemBuilder.new(item_data, @logger)

    assert_raises(ActiveRecord::RecordInvalid) do
      builder.call
    end
  end

  test 'should handle nil price gracefully' do
    item_data = { 'name' => 'Test Item', 'price' => nil }
    builder = MenuItemBuilder.new(item_data, @logger)

    assert_raises(ActiveRecord::RecordInvalid) do
      builder.call
    end
  end
end
