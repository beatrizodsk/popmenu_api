class MenuBuilder
  def initialize(menu_data, restaurant, logger)
    @menu_data = menu_data
    @restaurant = restaurant
    @logger = logger
  end

  def call
    menu_name = @menu_data['name']
    normalized_name = normalize_name(menu_name)

    menu = Menu.joins(:restaurant)
               .where('LOWER(TRIM(menus.name)) = ? AND restaurants.id = ?', normalized_name, @restaurant.id)
               .first

    if menu
      @logger.log_warning("Menu already exists: '#{menu_name}' in restaurant '#{@restaurant.name}'")
    else
      menu = Menu.create!(name: menu_name.to_s.strip, restaurant: @restaurant)
      @logger.log_info("Created menu '#{menu_name}' for restaurant '#{@restaurant.name}'")
    end

    menu
  rescue ActiveRecord::RecordInvalid => e
    @logger.log_error("Failed to create menu '#{menu_name}' for restaurant '#{@restaurant.name}': #{e.message}")
    raise
  end

  private

  def normalize_name(name)
    name.to_s.strip.squeeze(' ').downcase
  end
end
