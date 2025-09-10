module FileUploadValidation
  extend ActiveSupport::Concern

  MAX_FILE_SIZE = 10.megabytes
  ALLOWED_CONTENT_TYPES = ['application/json', 'text/json', 'application/octet-stream'].freeze

  private

  def validate_file_upload
    return if request.content_type&.include?('application/json')

    return if valid_file?

    render json: {
      success: false,
      message: validation_error_message,
      results: nil,
    }, status: :bad_request
  end

  def valid_file?
    params[:file].present? &&
      params[:file].size <= MAX_FILE_SIZE &&
      valid_content_type?
  end

  def valid_content_type?
    return false unless params[:file].present?

    content_type = params[:file].content_type
    file_extension = File.extname(params[:file].original_filename).downcase

    ALLOWED_CONTENT_TYPES.include?(content_type) || file_extension == '.json'
  end

  def validation_error_message
    return 'No file provided' unless params[:file].present?
    if params[:file].size > MAX_FILE_SIZE
      return "File size exceeds maximum allowed size of #{MAX_FILE_SIZE / 1.megabyte}MB"
    end

    'Invalid file type. Expected JSON'
  end
end
