class ImportRestaurantsService
  def initialize(file, cli_mode: false)
    @file = file
    @logger = ImportLogger.new(cli_mode: cli_mode)
    @summary_data = {
      restaurants_processed: 0,
      menus_created: 0,
      menu_items_created: 0,
      associations_created: 0,
    }
  end

  def call
    @logger.log_cli_header('Restaurant Import Tool') if @logger.instance_variable_get(:@cli_mode)

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
    @logger.log_cli_section('Processing import...') if @logger.instance_variable_get(:@cli_mode)

    normalized_data['restaurants']&.each do |restaurant_data|
      process_restaurant(restaurant_data)
      @summary_data[:restaurants_processed] += 1
    end
  end

  def process_restaurant(restaurant_data)
    restaurant = RestaurantBuilder.new(restaurant_data, @logger).call

    restaurant_data['menus']&.each do |menu_data|
      process_menu(menu_data, restaurant)
    end
  end

  def process_menu(menu_data, restaurant)
    menu_name = menu_data['name']
    normalized_name = menu_name.to_s.strip.squeeze(' ').downcase

    existing_menu = restaurant.menus.find_by('LOWER(TRIM(name)) = ?', normalized_name)

    menu = MenuBuilder.new(menu_data, restaurant, @logger).call

    @summary_data[:menus_created] += 1 unless existing_menu

    menu_data['menu_items']&.each do |item_data|
      process_menu_item(item_data, menu)
    end
  end

  def process_menu_item(item_data, menu)
    item_name = item_data['name']
    item_price = item_data['price']
    normalized_name = item_name.to_s.strip.squeeze(' ').downcase

    existing_menu_item = MenuItem.find_by('LOWER(TRIM(name)) = ? AND price = ?', normalized_name, item_price)

    menu_item_builder = MenuItemBuilder.new(item_data, @logger)
    menu_item = menu_item_builder.call
    @summary_data[:menu_items_created] += 1 unless existing_menu_item

    association_exists = menu.menu_items.exists?(menu_item.id)

    menu_item_builder.associate_with_menu(menu_item, menu)

    @summary_data[:associations_created] += 1 unless association_exists
  end

  def build_result
    result = @logger.summary.merge(
      success: true,
      message: 'Import completed successfully within transaction',
      summary_data: @summary_data
    )

    @logger.log_cli_summary(@summary_data) if @logger.instance_variable_get(:@cli_mode)

    result
  end
end
