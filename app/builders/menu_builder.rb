class MenuBuilder
  def initialize(menu_data, restaurant, logger)
    @menu_data = menu_data
    @restaurant = restaurant
    @logger = logger
  end

  def call
    menu_name = @menu_data['name']

    @logger.log_info("Creating menu '#{menu_name}' for restaurant '#{@restaurant.name}'")

    menu = Menu.create!(
      name: menu_name,
      restaurant: @restaurant
    )

    @logger.log_info("Successfully created menu '#{menu_name}' for restaurant '#{@restaurant.name}'")
    menu
  rescue ActiveRecord::RecordInvalid => e
    @logger.log_error("Failed to create menu '#{menu_name}' for restaurant '#{@restaurant.name}': #{e.message}")
    raise
  end
end
