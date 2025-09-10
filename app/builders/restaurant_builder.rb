class RestaurantBuilder
  def initialize(restaurant_data, logger)
    @restaurant_data = restaurant_data
    @logger = logger
  end

  def call
    restaurant_name = @restaurant_data['name']
    normalized_name = normalize_name(restaurant_name)

    restaurant = Restaurant.find_by('LOWER(TRIM(name)) = ?', normalized_name)

    if restaurant
      @logger.log_warning("Restaurant already exists: #{restaurant.name}")
      restaurant
    else
      restaurant = Restaurant.create!(name: restaurant_name.to_s.strip)
      @logger.log_info("Created restaurant: #{restaurant_name}")
      restaurant
    end
  rescue ActiveRecord::RecordInvalid => e
    @logger.log_error("Failed to create restaurant '#{restaurant_name}': #{e.message}")
    raise
  end

  private

  def normalize_name(name)
    name.to_s.strip.squeeze(' ').downcase
  end
end
