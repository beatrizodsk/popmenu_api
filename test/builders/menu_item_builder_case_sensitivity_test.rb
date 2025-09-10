require 'test_helper'

class MenuItemBuilderCaseSensitivityTest < ActiveSupport::TestCase
  def setup
    @logger = ImportLogger.new
  end

  test 'should find existing item with different case and preserve original name' do
    create(:menu_item, name: 'Burger', price: 9.00)

    item_data = { 'name' => 'burger', 'price' => 9.00 }
    builder = MenuItemBuilder.new(item_data, @logger)

    assert_no_difference('MenuItem.count') do
      found_item = builder.call
      assert_equal 'Burger', found_item.name
      assert_equal 9.00, found_item.price
    end
  end

  test 'should create separate items for same case-insensitive name but different prices' do
    create(:menu_item, name: 'Burger', price: 9.00)

    item_data = { 'name' => 'burger', 'price' => 15.00 }
    builder = MenuItemBuilder.new(item_data, @logger)

    assert_difference('MenuItem.count', 1) do
      new_item = builder.call
      assert_equal 'burger', new_item.name
      assert_equal 15.00, new_item.price
    end

    assert_equal 2, MenuItem.count
    items = MenuItem.order(:price)
    assert_equal 'Burger', items.first.name
    assert_equal 9.00, items.first.price
    assert_equal 'burger', items.last.name
    assert_equal 15.00, items.last.price
  end

  test 'should handle multiple case variations correctly' do
    create(:menu_item, name: 'Pizza', price: 12.00)

    variations = ['pizza', 'PIZZA', 'PiZzA', '  pizza  ']

    variations.each do |variation|
      item_data = { 'name' => variation, 'price' => 12.00 }
      builder = MenuItemBuilder.new(item_data, @logger)

      assert_no_difference('MenuItem.count') do
        found_item = builder.call
        assert_equal 'Pizza', found_item.name
        assert_equal 12.00, found_item.price
      end
    end
  end

  test 'should handle whitespace variations correctly' do
    create(:menu_item, name: 'French Fries', price: 5.00)

    variations = ['  french fries  ', 'french fries', 'FRENCH FRIES']

    variations.each do |variation|
      item_data = { 'name' => variation, 'price' => 5.00 }
      builder = MenuItemBuilder.new(item_data, @logger)

      assert_no_difference('MenuItem.count') do
        found_item = builder.call
        assert_equal 'French Fries', found_item.name
        assert_equal 5.00, found_item.price
      end
    end
  end

  test 'should create items with trimmed names when creating new' do
    item_data = { 'name' => '  New Item  ', 'price' => 8.00 }
    builder = MenuItemBuilder.new(item_data, @logger)

    assert_difference('MenuItem.count', 1) do
      new_item = builder.call
      assert_equal 'New Item', new_item.name
      assert_equal 8.00, new_item.price
    end
  end

  test 'should handle complex case and whitespace scenarios' do
    create(:menu_item, name: 'Caesar Salad', price: 8.00)

    variations = [
      'caesar salad',
      'CAESAR SALAD',
      '  caesar salad  ',
      'CaEsAr SaLaD',
    ]

    variations.each do |variation|
      item_data = { 'name' => variation, 'price' => 8.00 }
      builder = MenuItemBuilder.new(item_data, @logger)

      assert_no_difference('MenuItem.count') do
        found_item = builder.call
        assert_equal 'Caesar Salad', found_item.name
        assert_equal 8.00, found_item.price
      end
    end

    item_data = { 'name' => 'caesar   salad', 'price' => 8.00 }
    builder = MenuItemBuilder.new(item_data, @logger)

    assert_no_difference('MenuItem.count') do
      found_item = builder.call
      assert_equal 'Caesar Salad', found_item.name
      assert_equal 8.00, found_item.price
    end
  end

  test 'should log appropriate messages for case-insensitive matches' do
    create(:menu_item, name: 'Burger', price: 9.00)

    item_data = { 'name' => 'burger', 'price' => 9.00 }
    builder = MenuItemBuilder.new(item_data, @logger)

    builder.call

    logs = @logger.summary[:logs]
    assert(logs.any? { |log| log[:message].include?('Found existing menu item') })
    assert(logs.any? { |log| log[:message].include?('Burger') })
  end
end
