# PopMenu API

A Rails API for managing restaurants, menus, and menu items with import capabilities.

## Features

- Restaurant management with menus and menu items
- JSON import functionality via HTTP API and CLI tool
- Data normalization and validation
- Comprehensive logging and error handling

## Setup

### Prerequisites

- Ruby 3.3.9
- Rails 7.1.5+

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```

3. Setup the database:
   ```bash
   rails db:setup
   ```

## Development Approach

### Level 1: Basics
- Simple 1:N relationship (Menu has_many MenuItems)
- Basic models with validations and REST endpoints

### Level 2: Multiple Menus
- Evolved to Many-to-Many relationship for MenuItem sharing
- Same item can appear on multiple menus (price is stored on MenuItem, not per association)
- Added join table (menu_items_menus)

### Level 3: JSON Import
- Separate CLI tool alongside HTTP API
- Service layer with Builder pattern for object creation
- JsonDataNormalizer handles multiple JSON formats (dishes/menu_items)

**Key Assumptions:**
- Menu items unique by name (case-insensitive)
- Restaurant names globally unique
- Menu names unique within each restaurant
- Atomic imports with database transactions
- Support for both file upload and direct JSON

## Architecture

**Domain-Driven Design with clean layered architecture:**

### Core Components
- **Services**: ImportRestaurantsService (orchestrator), ImportLogger (dual-mode logging)
- **Builders**: RestaurantBuilder, MenuBuilder, MenuItemBuilder (consistent object creation)
- **Data Processing**: JsonDataNormalizer (flexible JSON format handling, name sanitization, price validation)
- **API**: V1 Controllers (RESTful endpoints with proper error handling)

## CLI Import Tool

The application includes a command-line tool for importing restaurant data from JSON files.

### Usage

```bash
rails "import:restaurants[path/to/file.json]"
rails import:help
```

### JSON Format
```json
{
  "restaurants": [
    {
      "name": "Restaurant Name",
      "menus": [
        {
          "name": "menu_name",
          "menu_items": [
            {"name": "Item Name", "price": 9.99}
          ]
        }
      ]
    }
  ]
}
```

### Data Processing Features
- **Name Sanitization**: Automatically cleans item names by removing escaped quotes and trimming whitespace
- **Price Validation**: Validates price format (numeric or string with decimal format) and converts to float
- **Format Flexibility**: Handles both `"menu_items"` and `"dishes"` keys for backward compatibility

### CLI Output
```
🍽️  Restaurant Import Tool
📁 Reading file: test/fixtures/files/restaurant_data.json
✓ File validated successfully

📊 Processing import...
✓ Created restaurant: Poppo's Cafe
  ✓ Created menu 'lunch' with 2 items
  ✓ Created menu 'dinner' with 2 items

📈 Import Summary:
- Restaurants processed: 2
- Menus created: 4
- Menu items created: 7
- Associations created: 9
- Errors: 0
- Warnings: 0

✅ Import completed successfully in 0.45 seconds
```

## API Endpoints

### Import
- **POST** `/v1/imports/restaurants`
  - File size limit: 10MB maximum
  - Supported formats: JSON files (.json) or direct JSON in request body
  - Content types: application/json, text/json

### REST Resources
- **Restaurants**: `/v1/restaurants` (GET, POST, GET/:id, PATCH/:id, DELETE/:id)
- **Menus**: `/v1/menus` (GET, POST, GET/:id, PATCH/:id, DELETE/:id)
  - Nested: `/v1/restaurants/:restaurant_id/menus` (GET, POST)
- **Menu Items**: `/v1/menu_items` (GET, POST, GET/:id, PATCH/:id, DELETE/:id)
  - Nested: `/v1/menus/:menu_id/menu_items` (GET, POST)
  - Nested: `/v1/restaurants/:restaurant_id/menus/:menu_id/menu_items` (GET, POST)

## Testing

```bash
rails test                    # Full suite
rails test test/models/       # Models only
rails test test/controllers/  # Controllers only
rails test test/services/     # Services only
```

**Coverage:** 17 test files covering models, controllers, services, builders with edge cases, integration tests, and error scenarios.
