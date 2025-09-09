require 'test_helper'

class V1::MenuItemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @menu = create(:menu)
    @menu_item = create(:menu_item, menu: @menu)
    @menu_item_params = { menu_item: { name: 'New Item', price: 12.99, menu_id: @menu.id } }
    @invalid_menu_item_params = { menu_item: { name: '', price: -1 } }
  end

  test 'should get index' do
    get v1_menu_items_url
    assert_response :success
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  test 'should return all menu items with menu' do
    get v1_menu_items_url
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 1, json_response.length
    assert_equal @menu_item.name, json_response.first['name']
    assert_equal @menu_item.price.to_s, json_response.first['price']
    assert_equal @menu.name, json_response.first['menu']['name']
  end

  test 'should return empty array when no menu items exist' do
    MenuItem.destroy_all

    get v1_menu_items_url
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal [], json_response
  end

  test 'should get show' do
    get v1_menu_item_url(@menu_item)
    assert_response :success
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  test 'should return menu item with menu' do
    get v1_menu_item_url(@menu_item)
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal @menu_item.name, json_response['name']
    assert_equal @menu_item.price.to_s, json_response['price']
    assert_equal @menu.name, json_response['menu']['name']
  end

  test 'should return 404 for non-existent menu item' do
    get v1_menu_item_url(id: 99_999)
    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_equal 'Menu item not found', json_response['error']
  end

  test 'should not create menu item with invalid params' do
    assert_no_difference('MenuItem.count') do
      post v1_menu_items_url, params: @invalid_menu_item_params, as: :json
    end

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_includes json_response['errors']['name'], "can't be blank"
    assert_includes json_response['errors']['price'], 'must be greater than 0'
  end

  test 'should create menu item with menu association' do
    post v1_menu_items_url, params: @menu_item_params, as: :json

    assert_response :created

    json_response = JSON.parse(response.body)
    assert_equal @menu.name, json_response['menu']['name']
  end

  test 'should not update menu item with invalid params' do
    original_name = @menu_item.name
    original_price = @menu_item.price

    patch v1_menu_item_url(@menu_item), params: @invalid_menu_item_params, as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_includes json_response['errors']['name'], "can't be blank"
    assert_includes json_response['errors']['price'], 'must be greater than 0'

    @menu_item.reload
    assert_equal original_name, @menu_item.name
    assert_equal original_price, @menu_item.price
  end

  test 'should return 404 when updating non-existent menu item' do
    patch v1_menu_item_url(id: 99_999), params: @menu_item_params, as: :json

    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_equal 'Menu item not found', json_response['error']
  end

  test 'should not affect menu when menu item is destroyed' do
    menu_id = @menu.id

    delete v1_menu_item_url(@menu_item)

    assert_response :no_content
    assert Menu.find(menu_id)
    assert_equal 0, @menu.menu_items.count
  end

  test 'should get menu items for specific menu' do
    other_menu = create(:menu, name: 'Other Menu')
    other_item = create(:menu_item, name: 'Other Item', price: 8.99, menu: other_menu)

    get v1_menu_menu_items_url(@menu)
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 1, json_response.length
    assert_equal @menu_item.name, json_response.first['name']
    assert_not_includes json_response.map { |item| item['name'] }, other_item.name
  end

  test 'should create menu item for specific menu' do
    assert_difference('MenuItem.count') do
      post v1_menu_menu_items_url(@menu), params: { menu_item: { name: 'Nested Item', price: 11.99 } }, as: :json
    end

    assert_response :created

    json_response = JSON.parse(response.body)
    assert_equal 'Nested Item', json_response['name']
    assert_equal @menu.id, json_response['menu_id']
    assert_equal @menu.name, json_response['menu']['name']
  end

  test 'should return 404 for non-existent menu in nested route' do
    get v1_menu_menu_items_url(menu_id: 99_999)
    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_equal 'Menu not found', json_response['error']
  end

  test 'should handle missing menu_item parameter' do
    post v1_menu_items_url, params: {}, as: :json

    assert_response :bad_request
  end

  test 'should handle extra parameters gracefully' do
    extra_params = { menu_item: { name: 'Test Item', price: 9.99, menu_id: @menu.id, extra_field: 'ignored' } }

    post v1_menu_items_url, params: extra_params, as: :json

    assert_response :created

    json_response = JSON.parse(response.body)
    assert_equal 'Test Item', json_response['name']
    assert_nil json_response['extra_field']
  end

  test 'should include menu in response' do
    get v1_menu_item_url(@menu_item)

    json_response = JSON.parse(response.body)
    assert_not_nil json_response['menu']
    assert_equal @menu.name, json_response['menu']['name']
  end
end
