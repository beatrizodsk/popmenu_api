require 'test_helper'

class RestaurantBuilderTest < ActiveSupport::TestCase
  def setup
    @logger = ImportLogger.new
  end

  test 'should create new restaurant when none exists' do
    restaurant_data = { 'name' => 'McDonalds' }
    builder = RestaurantBuilder.new(restaurant_data, @logger)

    assert_difference('Restaurant.count', 1) do
      restaurant = builder.call
      assert_equal 'McDonalds', restaurant.name
    end
  end

  test 'should find existing restaurant when exact match exists' do
    create(:restaurant, name: 'McDonalds')
    restaurant_data = { 'name' => 'McDonalds' }
    builder = RestaurantBuilder.new(restaurant_data, @logger)

    assert_no_difference('Restaurant.count') do
      found_restaurant = builder.call
      assert_equal 'McDonalds', found_restaurant.name
    end
  end

  test 'should find restaurant case-insensitive' do
    create(:restaurant, name: 'McDonalds')
    restaurant_data = { 'name' => 'mcdonalds' }
    builder = RestaurantBuilder.new(restaurant_data, @logger)

    assert_no_difference('Restaurant.count') do
      found_restaurant = builder.call
      assert_equal 'McDonalds', found_restaurant.name
    end
  end

  test 'should find restaurant ignoring extra whitespace' do
    create(:restaurant, name: 'Burger King')
    restaurant_data = { 'name' => '  burger king  ' }
    builder = RestaurantBuilder.new(restaurant_data, @logger)

    assert_no_difference('Restaurant.count') do
      found_restaurant = builder.call
      assert_equal 'Burger King', found_restaurant.name
    end
  end

  test 'should create restaurant with normalized name' do
    restaurant_data = { 'name' => '  New Restaurant  ' }
    builder = RestaurantBuilder.new(restaurant_data, @logger)

    assert_difference('Restaurant.count', 1) do
      restaurant = builder.call
      assert_equal 'New Restaurant', restaurant.name # whitespace trimmed
    end
  end

  test 'should handle mixed case variations' do
    create(:restaurant, name: 'Pizza Hut')
    restaurant_data = { 'name' => 'PIZZA HUT' }
    builder = RestaurantBuilder.new(restaurant_data, @logger)

    assert_no_difference('Restaurant.count') do
      found_restaurant = builder.call
      assert_equal 'Pizza Hut', found_restaurant.name
    end
  end

  test 'should log appropriate messages for existing restaurant' do
    create(:restaurant, name: 'McDonalds')
    restaurant_data = { 'name' => 'mcdonalds' }
    builder = RestaurantBuilder.new(restaurant_data, @logger)

    builder.call

    logs = @logger.summary[:logs]
    assert(logs.any? { |log| log[:message].include?('Found existing restaurant') })
  end

  test 'should log appropriate messages for new restaurant' do
    restaurant_data = { 'name' => 'New Restaurant' }
    builder = RestaurantBuilder.new(restaurant_data, @logger)

    builder.call

    logs = @logger.summary[:logs]
    assert(logs.any? { |log| log[:message].include?('Successfully created restaurant') })
  end

  test 'should handle restaurant creation errors gracefully' do
    restaurant_data = { 'name' => '' } # invalid name
    builder = RestaurantBuilder.new(restaurant_data, @logger)

    assert_raises(ActiveRecord::RecordInvalid) do
      builder.call
    end

    logs = @logger.summary[:logs]
    assert(logs.any? { |log| log[:message].include?('Failed to create restaurant') })
  end

  test 'should preserve original restaurant name when finding existing' do
    existing_restaurant = create(:restaurant, name: 'McDonalds')
    restaurant_data = { 'name' => 'mcdonalds' }
    builder = RestaurantBuilder.new(restaurant_data, @logger)

    found_restaurant = builder.call
    assert_equal 'McDonalds', found_restaurant.name
    assert_equal existing_restaurant.id, found_restaurant.id
  end

  test 'should handle nil name gracefully' do
    restaurant_data = { 'name' => nil }
    builder = RestaurantBuilder.new(restaurant_data, @logger)

    assert_raises(ActiveRecord::RecordInvalid) do
      builder.call
    end
  end
end
