class ImportRestaurantsService
  def initialize(file)
    @file = file
    @logger = ImportLogger.new
  end

  def call
    ActiveRecord::Base.transaction do
      json_data = parse_input
      normalized_data = normalize_data(json_data)
      import_data(normalized_data)
      build_result
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
    @logger.log_error("Transaction rolled back due to: #{e.message}")
    raise
  rescue StandardError => e
    @logger.log_error("Unexpected error during import: #{e.message}")
    raise
  end

  private

  def parse_input
    if @file.is_a?(Hash)
      @file
    else
      @file.rewind
      JSON.parse(@file.read)
    end
  rescue JSON::ParserError => e
    raise ArgumentError, "Invalid JSON format: #{e.message}"
  end

  def normalize_data(json_data)
    JsonDataNormalizer.new.normalize(json_data)
  end

  def import_data(normalized_data)
    normalized_data['restaurants']&.each do |restaurant_data|
      process_restaurant(restaurant_data)
    end
  end

  def process_restaurant(restaurant_data)
    @logger.log_info("Processing restaurant: #{restaurant_data['name']}")

    restaurant = RestaurantBuilder.new(restaurant_data, @logger).call

    restaurant_data['menus']&.each do |menu_data|
      process_menu(menu_data, restaurant)
    end
  end

  def process_menu(menu_data, restaurant)
    @logger.log_info("Processing menu: #{menu_data['name']} for restaurant: #{restaurant.name}")

    menu = MenuBuilder.new(menu_data, restaurant, @logger).call

    menu_data['menu_items']&.each do |item_data|
      process_menu_item(item_data, menu)
    end
  end

  def process_menu_item(item_data, menu)
    @logger.log_info("Processing menu item: #{item_data['name']} for menu: #{menu.name}")

    menu_item_builder = MenuItemBuilder.new(item_data, @logger)
    menu_item = menu_item_builder.call
    menu_item_builder.associate_with_menu(menu_item, menu)
  end

  def build_result
    @logger.summary.merge(
      success: true,
      message: 'Import completed successfully within transaction'
    )
  end
end
