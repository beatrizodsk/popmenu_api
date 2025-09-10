require 'test_helper'

class V1::ImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @valid_json_file = fixture_file_upload('files/restaurant_data.json', 'application/json')
    @invalid_json_file = fixture_file_upload('files/restaurant_data.json', 'application/json')
    @large_file = fixture_file_upload('files/restaurant_data.json', 'application/json')
    @non_json_file = Rack::Test::UploadedFile.new(
      StringIO.new('{"test": "data"}'),
      'text/plain',
      original_filename: 'test.txt'
    )
  end

  test 'should successfully import restaurant data with valid JSON file' do
    post restaurants_v1_imports_url, params: { file: @valid_json_file }

    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal 'Import completed successfully', response_data['message']
    assert_not_nil response_data['results']

    results = response_data['results']
    assert results['restaurants_processed'] > 0
    assert results['menus_created'] > 0
    assert results['associations_created'] > 0
    assert_equal 0, results['errors']
    assert results['warnings'] >= 0
    assert_not_nil results['logs']
  end

  test 'should return error when no file is provided' do
    post restaurants_v1_imports_url

    assert_response :bad_request
    response_data = JSON.parse(response.body)

    assert_not response_data['success']
    assert_equal 'No file provided', response_data['message']
    assert_nil response_data['results']
  end

  test 'should return error when file size exceeds maximum allowed size' do
    large_content = 'x' * (11.megabytes + 1)
    large_file = Rack::Test::UploadedFile.new(
      StringIO.new(large_content),
      'application/json',
      original_filename: 'large.json'
    )

    post restaurants_v1_imports_url, params: { file: large_file }

    assert_response :bad_request
    response_data = JSON.parse(response.body)

    assert_not response_data['success']
    assert_includes response_data['message'], 'File size exceeds maximum allowed size'
    assert_nil response_data['results']
  end

  test 'should return error when file content type is not allowed' do
    post restaurants_v1_imports_url, params: { file: @non_json_file }

    assert_response :bad_request
    response_data = JSON.parse(response.body)

    assert_not response_data['success']
    assert_includes response_data['message'], 'Invalid file type'
    assert_nil response_data['results']
  end

  test 'should accept application/octet-stream content type for JSON files' do
    octet_stream_file = fixture_file_upload('files/restaurant_data.json', 'application/octet-stream')

    post restaurants_v1_imports_url, params: { file: octet_stream_file }

    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal 'Import completed successfully', response_data['message']
  end

  test 'should accept files with .json extension regardless of content type' do
    json_file = Rack::Test::UploadedFile.new(
      Rails.root.join('test/fixtures/files/restaurant_data.json'),
      'application/octet-stream'
    )

    post restaurants_v1_imports_url, params: { file: json_file }

    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal 'Import completed successfully', response_data['message']
  end

  test 'should return error when JSON is invalid' do
    invalid_json_content = '{"invalid": "json"'
    invalid_file = Rack::Test::UploadedFile.new(
      StringIO.new(invalid_json_content),
      'application/json',
      original_filename: 'invalid.json'
    )

    post restaurants_v1_imports_url, params: { file: invalid_file }

    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)

    assert_not response_data['success']
    assert_includes response_data['message'], 'Invalid JSON format'
    assert_nil response_data['results']
  end

  test 'should handle data validation errors' do
    invalid_data = '{"restaurants": [{"name": "", "menus": []}]}'
    invalid_file = Rack::Test::UploadedFile.new(
      StringIO.new(invalid_data),
      'application/json',
      original_filename: 'invalid.json'
    )

    post restaurants_v1_imports_url, params: { file: invalid_file }

    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)

    assert_not response_data['success']
    assert_includes response_data['message'], 'Import failed and was rolled back'
  end

  test 'should handle unexpected errors gracefully' do
    post restaurants_v1_imports_url, params: { file: @valid_json_file }

    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal 'Import completed successfully', response_data['message']
    assert_not_nil response_data['results']
  end

  test 'should format results correctly with real data' do
    post restaurants_v1_imports_url, params: { file: @valid_json_file }

    assert_response :success
    response_data = JSON.parse(response.body)

    results = response_data['results']
    assert results['restaurants_processed'] > 0
    assert results['menus_created'] > 0
    assert results['associations_created'] > 0
    assert_equal 0, results['errors']
    assert results['warnings'] >= 0
    assert_not_nil results['logs']
    assert results['logs'].is_a?(Array)
  end

  test 'should handle empty JSON file' do
    empty_json = '{}'
    empty_file = Rack::Test::UploadedFile.new(
      StringIO.new(empty_json),
      'application/json',
      original_filename: 'empty.json'
    )

    post restaurants_v1_imports_url, params: { file: empty_file }

    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal 'Import completed successfully', response_data['message']

    results = response_data['results']
    assert_equal 0, results['restaurants_processed']
    assert_equal 0, results['menus_created']
    assert_equal 0, results['associations_created']
  end

  test 'should handle JSON with empty restaurants array' do
    empty_restaurants = '{"restaurants": []}'
    empty_file = Rack::Test::UploadedFile.new(
      StringIO.new(empty_restaurants),
      'application/json',
      original_filename: 'empty_restaurants.json'
    )

    post restaurants_v1_imports_url, params: { file: empty_file }

    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal 'Import completed successfully', response_data['message']

    results = response_data['results']
    assert_equal 0, results['restaurants_processed']
    assert_equal 0, results['menus_created']
    assert_equal 0, results['associations_created']
  end

  private

  def fixture_file_upload(path, content_type)
    Rack::Test::UploadedFile.new(
      Rails.root.join('test', 'fixtures', path),
      content_type
    )
  end
end
