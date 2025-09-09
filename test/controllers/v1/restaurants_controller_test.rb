require 'test_helper'

class V1::RestaurantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restaurant = create(:restaurant)
  end

  test 'should get index' do
    get v1_restaurants_url
    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data.is_a?(Array)
  end

  test 'should create restaurant' do
    assert_difference('Restaurant.count') do
      post v1_restaurants_url, params: { restaurant: { name: 'New Restaurant' } }
    end

    assert_response :created
    assert_equal 'New Restaurant', Restaurant.last.name
  end

  test 'should not create restaurant with invalid params' do
    assert_no_difference('Restaurant.count') do
      post v1_restaurants_url, params: { restaurant: { name: '' } }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, 'errors'
  end

  test 'should show restaurant' do
    get v1_restaurant_url(@restaurant)
    assert_response :success
    assert_equal @restaurant.id, JSON.parse(response.body)['id']
  end

  test 'should return 404 for non-existent restaurant' do
    get v1_restaurant_url(99_999)
    assert_response :not_found
    assert_includes response.body, 'Restaurant not found'
  end

  test 'should update restaurant' do
    patch v1_restaurant_url(@restaurant), params: { restaurant: { name: 'Updated Restaurant' } }
    assert_response :success

    @restaurant.reload
    assert_equal 'Updated Restaurant', @restaurant.name
  end

  test 'should not update restaurant with invalid params' do
    original_name = @restaurant.name
    patch v1_restaurant_url(@restaurant), params: { restaurant: { name: '' } }
    assert_response :unprocessable_entity

    @restaurant.reload
    assert_equal original_name, @restaurant.name
  end

  test 'should return 404 when updating non-existent restaurant' do
    patch v1_restaurant_url(99_999), params: { restaurant: { name: 'Updated' } }
    assert_response :not_found
  end

  test 'should destroy restaurant' do
    assert_difference('Restaurant.count', -1) do
      delete v1_restaurant_url(@restaurant)
    end

    assert_response :no_content
  end

  test 'should return 404 when deleting non-existent restaurant' do
    delete v1_restaurant_url(99_999)
    assert_response :not_found
  end

  test 'should show restaurant with menus' do
    menu = create(:menu, restaurant: @restaurant)
    get v1_restaurant_url(@restaurant)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal 1, response_data['menus'].length
    assert_equal menu.id, response_data['menus'][0]['id']
  end

  test 'should handle restaurant with multiple menus' do
    menu1 = create(:menu, restaurant: @restaurant, name: 'Menu 1')
    menu2 = create(:menu, restaurant: @restaurant, name: 'Menu 2')

    get v1_restaurant_url(@restaurant)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal 2, response_data['menus'].length
    menu_names = response_data['menus'].map { |m| m['name'] }
    assert_includes menu_names, 'Menu 1'
    assert_includes menu_names, 'Menu 2'
  end

  test 'should handle restaurant with no menus' do
    get v1_restaurant_url(@restaurant)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal 0, response_data['menus'].length
  end

  test 'should destroy restaurant and associated menus' do
    menu = create(:menu, restaurant: @restaurant)
    menu_item = create(:menu_item, menu: menu)

    assert_difference('Restaurant.count', -1) do
      assert_difference('Menu.count', -1) do
        assert_difference('MenuItem.count', -1) do
          delete v1_restaurant_url(@restaurant)
        end
      end
    end

    assert_response :no_content
  end

  test 'should create restaurant with valid JSON format' do
    post v1_restaurants_url, params: { restaurant: { name: 'JSON Restaurant' } }
    assert_response :created

    response_data = JSON.parse(response.body)
    assert_equal 'JSON Restaurant', response_data['name']
    assert_not_nil response_data['id']
    assert_not_nil response_data['created_at']
    assert_not_nil response_data['updated_at']
  end

  test 'should return proper JSON content type' do
    get v1_restaurants_url
    assert_response :success
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  test 'should return proper error format for validation errors' do
    post v1_restaurants_url, params: { restaurant: { name: '' } }
    assert_response :unprocessable_entity

    response_data = JSON.parse(response.body)
    assert_includes response_data['errors']['name'], "can't be blank"
  end
end
