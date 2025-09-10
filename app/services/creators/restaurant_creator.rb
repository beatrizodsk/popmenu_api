class RestaurantCreator
  def initialize(logger:)
    @logger = logger
  end

  def create_or_find(restaurant_data)
    restaurant_name = restaurant_data['name']

    @logger.log_info("Looking for restaurant: #{restaurant_name}")

    restaurant = Restaurant.find_by(name: restaurant_name)

    if restaurant
      @logger.log_info("Found existing restaurant: #{restaurant_name}")
      restaurant
    else
      @logger.log_info("Creating new restaurant: #{restaurant_name}")
      restaurant = Restaurant.create!(name: restaurant_name)
      @logger.log_info("Successfully created restaurant: #{restaurant_name}")
      restaurant
    end
  rescue ActiveRecord::RecordInvalid => e
    @logger.log_error("Failed to create restaurant '#{restaurant_name}': #{e.message}")
    raise
  end
end
