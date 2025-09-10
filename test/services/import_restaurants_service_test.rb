require 'test_helper'

class ImportRestaurantsServiceTest < ActiveSupport::TestCase
  def setup
    @service = ImportRestaurantsService
  end

  test 'should handle repeated import without creating duplicates' do
    json_data = {
      'restaurants' => [
        {
          'name' => 'Test Restaurant',
          'menus' => [
            {
              'name' => 'lunch',
              'menu_items' => [
                { 'name' => 'Burger', 'price' => 10.00 },
              ],
            },
          ],
        },
      ],
    }

    assert_difference('Restaurant.count', 1) do
      assert_difference('Menu.count', 1) do
        assert_difference('MenuItem.count', 1) do
          @service.new(json_data).call
        end
      end
    end

    service2 = @service.new(json_data)
    assert_no_difference('Restaurant.count') do
      assert_no_difference('Menu.count') do
        assert_no_difference('MenuItem.count') do
          service2.call
        end
      end
    end

    assert_equal 1, Restaurant.count
    assert_equal 1, Menu.count
    assert_equal 1, MenuItem.count
  end

  test 'should handle case-insensitive restaurant names' do
    json_data = {
      'restaurants' => [
        { 'name' => 'McDonalds', 'menus' => [] },
        { 'name' => 'mcdonalds', 'menus' => [] },
      ],
    }

    assert_difference('Restaurant.count', 1) do
      @service.new(json_data).call
    end

    restaurant = Restaurant.first
    assert_equal 'McDonalds', restaurant.name
  end

  test 'should handle menu items with same name but different prices by reusing existing item' do
    json_data = {
      'restaurants' => [
        {
          'name' => 'Test Restaurant',
          'menus' => [
            {
              'name' => 'lunch',
              'menu_items' => [
                { 'name' => 'Burger', 'price' => 9.00 },
                { 'name' => 'burger', 'price' => 15.00 },
              ],
            },
          ],
        },
      ],
    }

    assert_difference('MenuItem.count', 1) do
      @service.new(json_data).call
    end

    burgers = MenuItem.where('LOWER(name) LIKE ?', '%burger%')
    assert_equal 1, burgers.count
    assert_equal 9.0, burgers.first.price # First price is preserved
  end

  test 'should handle multiple restaurants with same menu names' do
    json_data = {
      'restaurants' => [
        {
          'name' => 'Restaurant A',
          'menus' => [
            { 'name' => 'lunch', 'menu_items' => [] },
          ],
        },
        {
          'name' => 'Restaurant B',
          'menus' => [
            { 'name' => 'lunch', 'menu_items' => [] },
          ],
        },
      ],
    }

    assert_difference('Restaurant.count', 2) do
      assert_difference('Menu.count', 2) do
        @service.new(json_data).call
      end
    end

    restaurant_a = Restaurant.find_by(name: 'Restaurant A')
    restaurant_b = Restaurant.find_by(name: 'Restaurant B')

    assert_equal 1, restaurant_a.menus.count
    assert_equal 1, restaurant_b.menus.count
    assert_equal 'lunch', restaurant_a.menus.first.name
    assert_equal 'lunch', restaurant_b.menus.first.name
  end

  test 'should handle whitespace in names correctly' do
    json_data = {
      'restaurants' => [
        {
          'name' => '  Test Restaurant  ',
          'menus' => [
            {
              'name' => '  lunch  ',
              'menu_items' => [
                { 'name' => '  Burger  ', 'price' => 10.00 },
              ],
            },
          ],
        },
      ],
    }

    @service.new(json_data).call

    restaurant = Restaurant.first
    menu = restaurant.menus.first
    menu_item = MenuItem.first

    assert_equal 'Test Restaurant', restaurant.name
    assert_equal 'lunch', menu.name
    assert_equal 'Burger', menu_item.name
  end

  test 'should handle complex nested structure' do
    json_data = {
      'restaurants' => [
        {
          'name' => 'Pizza Palace',
          'menus' => [
            {
              'name' => 'lunch',
              'menu_items' => [
                { 'name' => 'Margherita Pizza', 'price' => 12.00 },
                { 'name' => 'Pepperoni Pizza', 'price' => 14.00 },
              ],
            },
            {
              'name' => 'dinner',
              'menu_items' => [
                { 'name' => 'Margherita Pizza', 'price' => 12.00 }, # same item, different menu
                { 'name' => 'Caesar Salad', 'price' => 8.00 },
              ],
            },
          ],
        },
      ],
    }

    assert_difference('Restaurant.count', 1) do
      assert_difference('Menu.count', 2) do
        assert_difference('MenuItem.count', 3) do
          @service.new(json_data).call
        end
      end
    end

    restaurant = Restaurant.first
    lunch_menu = restaurant.menus.find_by(name: 'lunch')
    dinner_menu = restaurant.menus.find_by(name: 'dinner')

    assert_equal 2, lunch_menu.menu_items.count
    assert_equal 2, dinner_menu.menu_items.count

    margherita = MenuItem.find_by(name: 'Margherita Pizza')
    assert margherita.menus.include?(lunch_menu)
    assert margherita.menus.include?(dinner_menu)
  end

  test 'should process real restaurant_data.json without errors' do
    json_file = Rails.root.join('test/fixtures/files/restaurant_data.json')
    json_data = JSON.parse(File.read(json_file))

    assert_nothing_raised do
      result = @service.new(json_data).call
      assert result[:success]
      assert_equal 0, result[:counts][:error] || 0
    end

    assert_equal 2, Restaurant.count
    assert_equal 4, Menu.count
    assert MenuItem.count >= 6
  end

  test 'should handle empty restaurants array' do
    json_data = { 'restaurants' => [] }

    assert_no_difference('Restaurant.count') do
      result = @service.new(json_data).call
      assert result[:success]
    end
  end

  test 'should handle restaurants with no menus' do
    json_data = {
      'restaurants' => [
        { 'name' => 'Empty Restaurant', 'menus' => [] },
      ],
    }

    assert_difference('Restaurant.count', 1) do
      assert_no_difference('Menu.count') do
        @service.new(json_data).call
      end
    end
  end

  test 'should handle menus with no menu items' do
    json_data = {
      'restaurants' => [
        {
          'name' => 'Test Restaurant',
          'menus' => [
            { 'name' => 'empty_menu', 'menu_items' => [] },
          ],
        },
      ],
    }

    assert_difference('Restaurant.count', 1) do
      assert_difference('Menu.count', 1) do
        assert_no_difference('MenuItem.count') do
          @service.new(json_data).call
        end
      end
    end
  end

  test 'should handle file input correctly' do
    json_data = {
      'restaurants' => [
        { 'name' => 'File Restaurant', 'menus' => [] },
      ],
    }

    # Simular file input
    file = StringIO.new(json_data.to_json)

    assert_difference('Restaurant.count', 1) do
      @service.new(file).call
    end
  end

  test 'should handle invalid JSON gracefully' do
    invalid_json = StringIO.new('{"invalid": json}')

    assert_raises(ArgumentError) do
      @service.new(invalid_json).call
    end
  end

  test 'should return proper result structure' do
    json_data = {
      'restaurants' => [
        {
          'name' => 'Test Restaurant',
          'menus' => [
            {
              'name' => 'lunch',
              'menu_items' => [
                { 'name' => 'Burger', 'price' => 10.00 },
              ],
            },
          ],
        },
      ],
    }

    result = @service.new(json_data).call

    assert result[:success]
    assert result[:counts].is_a?(Hash)
    assert result[:logs].is_a?(Array)
    assert result[:counts][:error] >= 0
  end

  test 'should rollback entire transaction when any record fails' do
    call_count = 0
    MenuItem.stubs(:create!).with do |attrs|
      call_count += 1
      raise ActiveRecord::RecordInvalid.new(MenuItem.new) if call_count == 2

      MenuItem.create!(attrs)
    end

    json_data = {
      'restaurants' => [
        {
          'name' => 'Test Restaurant',
          'menus' => [
            {
              'name' => 'lunch',
              'menu_items' => [
                { 'name' => 'Burger', 'price' => 10.00 },
                { 'name' => 'Pizza', 'price' => 12.00 },
                { 'name' => 'Salad', 'price' => 8.00 },
              ],
            },
          ],
        },
      ],
    }

    assert_raises(ActiveRecord::RecordInvalid) do
      @service.new(json_data).call
    end

    assert_equal 0, Restaurant.count
    assert_equal 0, Menu.count
    assert_equal 0, MenuItem.count
  end

  test 'should complete successfully when all records are valid' do
    json_data = {
      'restaurants' => [
        {
          'name' => 'Test Restaurant',
          'menus' => [
            {
              'name' => 'lunch',
              'menu_items' => [
                { 'name' => 'Burger', 'price' => 10.00 },
                { 'name' => 'Pizza', 'price' => 12.00 },
                { 'name' => 'Salad', 'price' => 8.00 },
              ],
            },
          ],
        },
      ],
    }

    result = @service.new(json_data).call

    assert result[:success]
    assert_equal 'Import completed successfully within transaction', result[:message]

    assert_equal 1, Restaurant.count
    assert_equal 1, Menu.count
    assert_equal 3, MenuItem.count
  end

  test 'should handle database constraint violations with rollback' do
    existing_restaurant = Restaurant.create!(name: 'Existing Restaurant')

    Restaurant.stubs(:create!).with do |_attrs|
      raise ActiveRecord::StatementInvalid.new('UNIQUE constraint failed')
    end

    json_data = {
      'restaurants' => [
        {
          'name' => 'New Restaurant',
          'menus' => [
            {
              'name' => 'lunch',
              'menu_items' => [
                { 'name' => 'Burger', 'price' => 10.00 },
              ],
            },
          ],
        },
      ],
    }

    assert_raises(ActiveRecord::StatementInvalid) do
      @service.new(json_data).call
    end

    assert_equal 1, Restaurant.count
    assert_equal existing_restaurant.id, Restaurant.first.id
    assert_equal 0, Menu.count
    assert_equal 0, MenuItem.count
  end

  test 'should handle transaction rollback on validation errors' do
    json_data = {
      'restaurants' => [
        {
          'name' => '',
          'menus' => [
            {
              'name' => 'lunch',
              'menu_items' => [
                { 'name' => 'Burger', 'price' => 10.00 },
              ],
            },
          ],
        },
      ],
    }

    assert_raises(ActiveRecord::RecordInvalid) do
      @service.new(json_data).call
    end

    assert_equal 0, Restaurant.count
    assert_equal 0, Menu.count
    assert_equal 0, MenuItem.count
  end
end
