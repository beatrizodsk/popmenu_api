# Zeitwerk configuration for custom directories
Rails.autoloaders.main.push_dir(Rails.root.join("app", "serializers"))
Rails.autoloaders.main.push_dir(Rails.root.join("app", "builders"))
