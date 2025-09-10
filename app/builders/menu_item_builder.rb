class MenuItemBuilder
  def initialize(item_data, logger)
    @item_data = item_data
    @logger = logger
  end

  def call
    item_name = @item_data['name']
    item_price = @item_data['price']
    normalized_name = normalize_name(item_name)

    menu_item = MenuItem.where('LOWER(TRIM(name)) = ? AND price = ?', normalized_name, item_price).first

    if menu_item
      @logger.log_warning("Menu item already exists: #{menu_item.name} with price #{item_price}")
      menu_item
    else
      menu_item = MenuItem.create!(name: item_name.to_s.strip.squeeze(' '), price: item_price)
      @logger.log_info("Created menu item: #{item_name} with price #{item_price}")
      menu_item
    end
  rescue ActiveRecord::RecordInvalid => e
    @logger.log_error("Failed to create menu item '#{item_name}' with price #{item_price}: #{e.message}")
    raise
  end

  def associate_with_menu(menu_item, menu)
    if menu.menu_items.include?(menu_item)
      @logger.log_warning("Menu item '#{menu_item.name}' already associated with menu '#{menu.name}'")
    else
      menu.menu_items << menu_item
      @logger.log_info("Associated menu item '#{menu_item.name}' with menu '#{menu.name}'")
    end
  rescue StandardError => e
    @logger.log_error("Failed to associate menu item '#{menu_item.name}' with menu '#{menu.name}': #{e.message}")
    raise
  end

  private

  def normalize_name(name)
    name.to_s.strip.squeeze(' ').downcase
  end
end
