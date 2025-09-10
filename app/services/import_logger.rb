class ImportLogger
  def initialize(cli_mode: false)
    @logs = []
    @counts = Hash.new(0)
    @cli_mode = cli_mode
    @start_time = Time.current
  end

  def log_info(message)
    @logs << { level: :info, message: message, timestamp: Time.current }
    @counts[:info] += 1

    return unless @cli_mode

    puts "✓ #{message}"
  end

  def log_warning(message)
    @logs << { level: :warning, message: message, timestamp: Time.current }
    @counts[:warning] += 1

    return unless @cli_mode

    puts "⚠️  #{message}"
  end

  def log_error(message)
    @logs << { level: :error, message: message, timestamp: Time.current }
    @counts[:error] += 1

    return unless @cli_mode

    puts "❌ #{message}"
  end

  def log_cli_header(message)
    return unless @cli_mode

    puts "\n🍽️  #{message}"
  end

  def log_cli_section(message)
    return unless @cli_mode

    puts "\n📊 #{message}"
  end

  def log_cli_file_info(message)
    return unless @cli_mode

    puts "📁 #{message}"
  end

  def log_cli_success(message)
    return unless @cli_mode

    puts "✅ #{message}"
  end

  def log_cli_summary(summary_data)
    return unless @cli_mode

    duration = Time.current - @start_time

    puts "\n📈 Import Summary:"
    puts "- Restaurants processed: #{summary_data[:restaurants_processed] || 0}"
    puts "- Menus created: #{summary_data[:menus_created] || 0}"
    puts "- Menu items created: #{summary_data[:menu_items_created] || 0}"
    puts "- Associations created: #{summary_data[:associations_created] || 0}"
    puts "- Errors: #{@counts[:error]}"
    puts "- Warnings: #{@counts[:warning]}"
    puts "\n✅ Import completed successfully in #{duration.round(2)} seconds"
  end

  def summary
    {
      logs: @logs,
      counts: @counts,
      duration: Time.current - @start_time,
    }
  end
end
