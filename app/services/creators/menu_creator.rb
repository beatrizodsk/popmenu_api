class MenuCreator
  def initialize(logger:)
    @logger = logger
  end

  def create_for_restaurant(menu_data, restaurant)
    menu_name = menu_data['name']

    @logger.log_info("Creating menu '#{menu_name}' for restaurant '#{restaurant.name}'")

    menu = Menu.create!(
      name: menu_name,
      restaurant: restaurant
    )

    @logger.log_info("Successfully created menu '#{menu_name}' for restaurant '#{restaurant.name}'")
    menu
  rescue ActiveRecord::RecordInvalid => e
    @logger.log_error("Failed to create menu '#{menu_name}' for restaurant '#{restaurant.name}': #{e.message}")
    raise
  end
end
