namespace :import do
  desc 'Import restaurants from JSON file'
  task :restaurants, [:file_path] => :environment do |_task, args|
    file_path = args[:file_path]

    if file_path.nil? || file_path.empty?
      puts '❌ Error: Please provide a file path'
      puts 'Usage: rails import:restaurants[path/to/your/file.json]'
      puts 'Example: rails import:restaurants[test/fixtures/files/restaurant_data.json]'
      exit 1
    end

    unless File.exist?(file_path)
      puts "❌ Error: File not found: #{file_path}"
      puts 'Please check the file path and try again.'
      exit 1
    end

    unless file_path.end_with?('.json')
      puts '❌ Error: File must be a JSON file (.json extension required)'
      exit 1
    end

    begin
      puts "📁 Reading file: #{file_path}"
      file_content = File.read(file_path)

      JSON.parse(file_content)
      puts '✓ File validated successfully'

      file_obj = StringIO.new(file_content)

      service = ImportRestaurantsService.new(file_obj, cli_mode: true)
      result = service.call

      if result[:counts][:error] > 0
        puts "\n❌ Import completed with #{result[:counts][:error]} error(s)"
        exit 1
      else
        puts "\n🎉 Import completed successfully!"
        exit 0
      end
    rescue JSON::ParserError => e
      puts '❌ Error: Invalid JSON format in file'
      puts "Details: #{e.message}"
      exit 1
    rescue StandardError => e
      puts '❌ Error: Import failed'
      puts "Details: #{e.message}"
      puts "\nFull error: #{e.backtrace.first(5).join("\n")}" if ENV['DEBUG']
      exit 1
    end
  end

  desc 'Show help for import tasks'
  task :help do
    puts <<~HELP
      🍽️  Restaurant Import CLI Tool

      Available tasks:

      rails import:restaurants[file_path]  - Import restaurants from JSON file
      rails import:help                     - Show this help message

      Examples:
        rails import:restaurants[test/fixtures/files/restaurant_data.json]
        rails import:restaurants[./data/my_restaurants.json]

      JSON File Format:
        {
          "restaurants": [
            {
              "name": "Restaurant Name",
              "menus": [
                {
                  "name": "menu_name",
                  "menu_items": [
                    {
                      "name": "Item Name",
                      "price": 9.99
                    }
                  ]
                }
              ]
            }
          ]
        }

      Note: The tool also supports "dishes" instead of "menu_items" for backward compatibility.
    HELP
  end
end
