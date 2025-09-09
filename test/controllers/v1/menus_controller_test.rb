require 'test_helper'

class V1::MenusControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = create(:restaurant)
    @menu = create(:menu, restaurant: @restaurant)
    @menu_params = { menu: { name: 'New Menu', restaurant_id: @restaurant.id } }
    @invalid_menu_params = { menu: { name: '' } }
  end

  test 'should get index' do
    get v1_menus_url
    assert_response :success
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  test 'should return all menus with menu items' do
    menu_item = create(:menu_item)
    @menu.menu_items << menu_item

    get v1_menus_url
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 1, json_response.length
    assert_equal @menu.name, json_response.first['name']
    assert_equal 1, json_response.first['menu_items'].length
    assert_equal menu_item.name, json_response.first['menu_items'].first['name']
  end

  test 'should return empty array when no menus exist' do
    Menu.destroy_all

    get v1_menus_url
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal [], json_response
  end

  test 'should get show' do
    get v1_menu_url(@menu)
    assert_response :success
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  test 'should return menu with menu items' do
    menu_item = create(:menu_item)
    @menu.menu_items << menu_item

    get v1_menu_url(@menu)
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal @menu.name, json_response['name']
    assert_equal 1, json_response['menu_items'].length
    assert_equal menu_item.name, json_response['menu_items'].first['name']
  end

  test 'should return 404 for non-existent menu' do
    get v1_menu_url(99_999)
    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_equal 'Menu not found', json_response['error']
  end

  test 'should create menu' do
    assert_difference('Menu.count') do
      post v1_menus_url, params: @menu_params, as: :json
    end

    assert_response :created
    assert_equal 'New Menu', Menu.last.name
  end

  test 'should create menu with empty menu_items array' do
    post v1_menus_url, params: @menu_params, as: :json

    assert_response :created

    json_response = JSON.parse(response.body)
    assert_equal [], json_response['menu_items']
  end

  test 'should not create menu with invalid params' do
    assert_no_difference('Menu.count') do
      post v1_menus_url, params: @invalid_menu_params, as: :json
    end

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_includes json_response['errors']['name'], "can't be blank"
  end

  test 'should handle missing menu parameter' do
    post v1_menus_url, params: {}, as: :json

    assert_response :bad_request
  end

  test 'should update menu' do
    patch v1_menu_url(@menu), params: { menu: { name: 'Updated Menu' } }, as: :json
    assert_response :success

    @menu.reload
    assert_equal 'Updated Menu', @menu.name
  end

  test 'should not update menu with invalid params' do
    original_name = @menu.name

    patch v1_menu_url(@menu), params: @invalid_menu_params, as: :json

    assert_response :unprocessable_entity

    @menu.reload
    assert_equal original_name, @menu.name
  end

  test 'should return 404 when updating non-existent menu' do
    patch v1_menu_url(99_999), params: @menu_params, as: :json

    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_equal 'Menu not found', json_response['error']
  end

  test 'should destroy menu' do
    assert_difference('Menu.count', -1) do
      delete v1_menu_url(@menu)
    end

    assert_response :no_content
  end

  test 'should return 404 when deleting non-existent menu' do
    delete v1_menu_url(99_999)

    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_equal 'Menu not found', json_response['error']
  end

  test 'should get menus for specific restaurant' do
    get v1_restaurant_menus_url(@restaurant)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert response_data.is_a?(Array)
    assert_equal 1, response_data.length
    assert_equal @menu.id, response_data[0]['id']
  end

  test 'should create menu for specific restaurant' do
    assert_difference('Menu.count') do
      post v1_restaurant_menus_url(@restaurant), params: { menu: { name: 'Restaurant Menu' } }, as: :json
    end

    assert_response :created
    menu = Menu.last
    assert_equal 'Restaurant Menu', menu.name
    assert_equal @restaurant.id, menu.restaurant_id
  end

  test 'should return empty array when restaurant has no menus' do
    empty_restaurant = create(:restaurant)
    get v1_restaurant_menus_url(empty_restaurant)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal [], response_data
  end

  test 'should return 404 for non-existent restaurant in nested route' do
    get v1_restaurant_menus_url(99_999)
    assert_response :not_found
    assert_includes response.body, 'Restaurant not found'
  end

  test 'should include menu_items in response' do
    get v1_menu_url(@menu)

    json_response = JSON.parse(response.body)
    assert_not_nil json_response['menu_items']
    assert json_response['menu_items'].is_a?(Array)
  end

  test 'should handle extra parameters' do
    extra_params = { menu: { name: 'Test Menu', restaurant_id: @restaurant.id, extra_field: 'ignored' } }

    post v1_menus_url, params: extra_params, as: :json

    assert_response :created

    json_response = JSON.parse(response.body)
    assert_equal 'Test Menu', json_response['name']
    assert_nil json_response['extra_field']
  end
end
