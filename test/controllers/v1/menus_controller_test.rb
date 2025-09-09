require 'test_helper'

class V1::MenusControllerTest < ActionDispatch::IntegrationTest
  def setup
    @menu = create(:menu)
    @menu_params = { menu: { name: 'New Menu' } }
    @invalid_menu_params = { menu: { name: '' } }
  end

  test 'should get index' do
    get v1_menus_url
    assert_response :success
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  test 'should return all menus with menu items' do
    menu_item = create(:menu_item, menu: @menu)

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
    menu_item = create(:menu_item, menu: @menu)

    get v1_menu_url(@menu)
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal @menu.name, json_response['name']
    assert_equal 1, json_response['menu_items'].length
    assert_equal menu_item.name, json_response['menu_items'].first['name']
  end

  test 'should return 404 for non-existent menu' do
    get v1_menu_url(id: 99_999)
    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_equal 'Menu not found', json_response['error']
  end

  test 'should not create menu with invalid params' do
    assert_no_difference('Menu.count') do
      post v1_menus_url, params: @invalid_menu_params, as: :json
    end

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_includes json_response['errors']['name'], "can't be blank"
  end

  test 'should create menu with empty menu_items array' do
    post v1_menus_url, params: @menu_params, as: :json

    assert_response :created

    json_response = JSON.parse(response.body)
    assert_equal [], json_response['menu_items']
  end

  test 'should not update menu with invalid params' do
    original_name = @menu.name

    patch v1_menu_url(@menu), params: @invalid_menu_params, as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_includes json_response['errors']['name'], "can't be blank"

    @menu.reload
    assert_equal original_name, @menu.name
  end

  test 'should return 404 when updating non-existent menu' do
    patch v1_menu_url(id: 99_999), params: @menu_params, as: :json

    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_equal 'Menu not found', json_response['error']
  end

  test 'should handle missing menu parameter' do
    post v1_menus_url, params: {}, as: :json

    assert_response :bad_request
  end

  test 'should handle extra parameters gracefully' do
    extra_params = { menu: { name: 'Test Menu', extra_field: 'ignored' } }

    post v1_menus_url, params: extra_params, as: :json

    assert_response :created

    json_response = JSON.parse(response.body)
    assert_equal 'Test Menu', json_response['name']
    assert_nil json_response['extra_field']
  end

  test 'should include menu_items in response' do
    get v1_menu_url(@menu)

    json_response = JSON.parse(response.body)
    assert_not_nil json_response['menu_items']
    assert json_response['menu_items'].is_a?(Array)
  end
end
