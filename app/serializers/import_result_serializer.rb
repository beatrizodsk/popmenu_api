class ImportResultSerializer
  def initialize(import_result)
    @result = import_result
  end

  def as_json
    {
      success: @result[:success],
      message: success_message,
      results: {
        restaurants_processed: count_restaurants_processed,
        menus_created: count_menus_created,
        menu_items_created: count_menu_items_created,
        associations_created: count_associations_created,
        errors: @result[:counts][:error] || 0,
        warnings: @result[:counts][:warning] || 0,
        logs: @result[:logs] || [],
      },
    }
  end

  private

  def success_message
    @result[:success] ? 'Import completed successfully' : 'Import failed'
  end

  def count_restaurants_processed
    @result[:logs]&.count { |log| log[:message].include?('Processing restaurant') } || 0
  end

  def count_menus_created
    @result[:logs]&.count { |log| log[:message].include?('Successfully created menu') } || 0
  end

  def count_menu_items_created
    @result[:logs]&.count { |log| log[:message].include?('Successfully created menu item') } || 0
  end

  def count_associations_created
    @result[:logs]&.count { |log| log[:message].include?('Successfully associated menu item') } || 0
  end
end
