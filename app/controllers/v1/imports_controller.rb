class V1::ImportsController < ApplicationController
  include FileUploadValidation

  before_action :validate_file_upload, only: [:restaurants]

  def restaurants
    return if performed?

    if params[:file].present?
      result = ImportRestaurantsService.new(params[:file]).call
    elsif request.content_type&.include?('application/json')
      json_data = JSON.parse(request.body.read)
      result = ImportRestaurantsService.new(json_data).call
    else
      render json: {
        success: false,
        message: 'No file provided or invalid content type',
        results: nil,
      }, status: :bad_request
      return
    end

    render json: ImportResultSerializer.new(result).as_json, status: :ok
  rescue ArgumentError => e
    render json: {
      success: false,
      message: "Data validation error: #{e.message}",
      results: nil,
    }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "Import failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: {
      success: false,
      message: "Internal server error during import: #{e.message}",
      results: nil,
    }, status: :internal_server_error
  end
end
