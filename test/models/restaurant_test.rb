require 'test_helper'

class RestaurantTest < ActiveSupport::TestCase
  test 'name should be present' do
    restaurant = build(:restaurant, name: '   ')
    assert_not restaurant.valid?
  end

  test 'name should not be nil' do
    restaurant = build(:restaurant, name: nil)
    assert_not restaurant.valid?
  end

  test 'name should not be empty' do
    restaurant = build(:restaurant, name: '')
    assert_not restaurant.valid?
  end

  test 'name should allow duplicates' do
    restaurant = create(:restaurant)
    duplicate_restaurant = build(:restaurant, name: restaurant.name)
    assert duplicate_restaurant.valid?
  end

  test 'should have many menus' do
    restaurant = create(:restaurant, :with_menus, menus_count: 3)
    assert_respond_to restaurant, :menus
    assert_equal 3, restaurant.menus.count
  end

  test 'should destroy associated menus when restaurant is destroyed' do
    restaurant = create(:restaurant)
    menu1 = create(:menu, restaurant: restaurant)
    menu2 = create(:menu, restaurant: restaurant)

    assert_equal 2, restaurant.menus.count

    restaurant.destroy

    assert_raises(ActiveRecord::RecordNotFound) { menu1.reload }
    assert_raises(ActiveRecord::RecordNotFound) { menu2.reload }
  end

  test 'should be valid without menus' do
    restaurant = create(:restaurant, :empty)
    assert restaurant.valid?
    assert_equal 0, restaurant.menus.count
  end
end
