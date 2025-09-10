require 'test_helper'

class MenuBuilderTest < ActiveSupport::TestCase
  def setup
    @logger = ImportLogger.new
    @restaurant = create(:restaurant, name: 'Test Restaurant')
  end

  test 'should create new menu when none exists' do
    menu_data = { 'name' => 'lunch' }
    builder = MenuBuilder.new(menu_data, @restaurant, @logger)

    assert_difference('Menu.count', 1) do
      menu = builder.call
      assert_equal 'lunch', menu.name
      assert_equal @restaurant, menu.restaurant
    end
  end

  test 'should find existing menu instead of creating duplicate' do
    existing_menu = create(:menu, name: 'lunch', restaurant: @restaurant)
    menu_data = { 'name' => 'lunch' }
    builder = MenuBuilder.new(menu_data, @restaurant, @logger)

    assert_no_difference('Menu.count') do
      found_menu = builder.call
      assert_equal existing_menu.id, found_menu.id
      assert_equal 'lunch', found_menu.name
    end
  end

  test 'should create menu with same name in different restaurant' do
    other_restaurant = create(:restaurant, name: 'Other Restaurant')
    create(:menu, name: 'lunch', restaurant: other_restaurant)

    menu_data = { 'name' => 'lunch' }
    builder = MenuBuilder.new(menu_data, @restaurant, @logger)

    assert_difference('Menu.count', 1) do
      menu = builder.call
      assert_equal 'lunch', menu.name
      assert_equal @restaurant, menu.restaurant
    end
  end

  test 'should log appropriate messages for existing menu' do
    create(:menu, name: 'lunch', restaurant: @restaurant)
    menu_data = { 'name' => 'lunch' }
    builder = MenuBuilder.new(menu_data, @restaurant, @logger)

    builder.call

    logs = @logger.summary[:logs]
    assert(logs.any? { |log| log[:message].include?('Menu already exists') })
  end

  test 'should log appropriate messages for new menu' do
    menu_data = { 'name' => 'lunch' }
    builder = MenuBuilder.new(menu_data, @restaurant, @logger)

    builder.call

    logs = @logger.summary[:logs]
    assert(logs.any? { |log| log[:message].include?('Created menu') })
  end

  test 'should handle menu creation errors gracefully' do
    menu_data = { 'name' => '' }
    builder = MenuBuilder.new(menu_data, @restaurant, @logger)

    assert_raises(ActiveRecord::RecordInvalid) do
      builder.call
    end

    logs = @logger.summary[:logs]
    assert(logs.any? { |log| log[:message].include?('Failed to create menu') })
  end

  test 'should preserve original menu name when finding existing' do
    existing_menu = create(:menu, name: 'Lunch Menu', restaurant: @restaurant)
    menu_data = { 'name' => 'Lunch Menu' }
    builder = MenuBuilder.new(menu_data, @restaurant, @logger)

    found_menu = builder.call
    assert_equal 'Lunch Menu', found_menu.name
    assert_equal existing_menu.id, found_menu.id
  end
end
