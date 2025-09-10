class RestaurantDataImporter
  def initialize(
    normalizer: JsonDataNormalizer.new,
    restaurant_creator: nil,
    menu_creator: nil,
    menu_item_creator: nil,
    logger: ImportLogger.new
  )
    @normalizer = normalizer
    @logger = logger
    @restaurant_creator = restaurant_creator || RestaurantCreator.new(logger: @logger)
    @menu_creator = menu_creator || MenuCreator.new(logger: @logger)
    @menu_item_creator = menu_item_creator || MenuItemCreator.new(logger: @logger)
    @success = false
  end

  def call(json_data)
    @logger.log_info('Starting restaurant data import')

    begin
      @logger.log_info('Normalizing JSON data')
      normalized_data = @normalizer.normalize(json_data)

      normalized_data['restaurants']&.each do |restaurant_data|
        process_restaurant(restaurant_data)
      end

      @success = true
      @logger.log_info('Restaurant data import completed successfully')
    rescue StandardError => e
      @logger.log_error("Restaurant data import failed: #{e.message}")
      @success = false
      raise
    end
  end

  def results
    @logger.summary.merge(success: @success)
  end

  private

  def process_restaurant(restaurant_data)
    @logger.log_info("Processing restaurant: #{restaurant_data['name']}")

    restaurant = @restaurant_creator.create_or_find(restaurant_data)

    restaurant_data['menus']&.each do |menu_data|
      process_menu(menu_data, restaurant)
    end
  end

  def process_menu(menu_data, restaurant)
    @logger.log_info("Processing menu: #{menu_data['name']} for restaurant: #{restaurant.name}")

    menu = @menu_creator.create_for_restaurant(menu_data, restaurant)

    menu_data['menu_items']&.each do |item_data|
      process_menu_item(item_data, menu)
    end
  end

  def process_menu_item(item_data, menu)
    @logger.log_info("Processing menu item: #{item_data['name']} for menu: #{menu.name}")

    menu_item = @menu_item_creator.create_or_find(item_data)
    @menu_item_creator.associate_with_menu(menu_item, menu)
  end
end
