class JsonDataNormalizer
  def normalize(json_data)
    normalized_data = json_data.deep_dup

    normalized_data['restaurants']&.each do |restaurant|
      restaurant['menus']&.each do |menu|
        normalize_menu_items(menu)
      end
    end

    normalized_data
  end

  private

  def normalize_menu_items(menu_data)
    menu_data['menu_items'] = menu_data.delete('dishes') if menu_data.key?('dishes')

    menu_data['menu_items']&.each do |item|
      item['name'] = sanitize_name(item['name'])
      validate_price(item['price'])
    end
  end

  def sanitize_name(name)
    return name if name.nil?

    name.to_s
        .gsub('\"', '"')
        .gsub('\\\'', "'")
        .strip
  end

  def validate_price(price)
    return price if price.nil?

    unless (price.is_a?(String) && price.match?(/^\d+\.?\d*$/)) || price.is_a?(Numeric)
      raise ArgumentError, "Invalid price format: #{price}"
    end

    price.to_f
  end
end
