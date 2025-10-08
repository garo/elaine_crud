# ElaineCrud Integration Test Suite

This directory contains comprehensive integration tests for the ElaineCrud demo application.

## Overview

The test suite validates all CRUD operations, custom layouts, field displays, sorting, and filtering functionality across all controllers in the demo app.

## Prerequisites

```bash
# Install dependencies
bundle install
```

## Running Tests

### All Tests
```bash
bundle exec rake spec
```

### Integration Tests Only
```bash
bundle exec rake spec:integration
```

### Specific Controller Tests
```bash
bundle exec rake spec:controller[libraries]
bundle exec rake spec:controller[books]
bundle exec rake spec:controller[members]
bundle exec rake spec:controller[librarians]
```

### Individual Test Files
```bash
bundle exec rspec spec/integration/libraries_crud_spec.rb
bundle exec rspec spec/integration/layout_features_spec.rb
```

### With Documentation Format
```bash
bundle exec rspec spec/integration --format documentation
```

## Test Structure

```
spec/
├── spec_helper.rb                    # RSpec and Rails configuration
├── support/
│   └── test_helpers.rb               # Helper methods for tests
└── integration/
    ├── libraries_crud_spec.rb        # 8 examples
    ├── books_crud_spec.rb            # 8 examples (includes multi-row tests)
    ├── members_crud_spec.rb          # 8 examples (includes dropdown tests)
    ├── librarians_crud_spec.rb       # 8 examples (includes currency tests)
    ├── layout_features_spec.rb       # 12 examples
    └── sorting_and_filtering_spec.rb # 6 examples
```

**Total: 50 integration tests**

## Test Categories

### 1. CRUD Operations (32 tests)

Each controller (Libraries, Books, Members, Librarians) is tested for:
- Index page display and record counts
- Field value display and formatting
- New record form rendering
- Creating new records
- Edit form rendering
- Updating existing records
- Deleting records
- Navigation links

### 2. Custom Layout Features (12 tests)

- Multi-row layout (Books controller)
- Column spanning (colspan attribute)
- Flexible grid columns with minmax()
- Responsive horizontal scrolling
- Custom field displays (currency, dates, booleans, emails)
- Grid borders and styling
- Alternating row colors
- Hover effects

### 3. Sorting and Filtering (6 tests)

- Default sort order validation
- Sortable column headers
- Sort indicators (↑ ↓)
- Column clicking for sorting
- Has-many relationship counts
- Relationship filtering

## Database Management

The test suite automatically:
1. **Before Suite**: Drops, creates, migrates, and seeds the test database
2. **Before Each Test**: Resets data to seed state
3. **After Each Test**: Rolls back transaction to maintain isolation

This ensures:
- ✅ Clean state for every test
- ✅ No test pollution
- ✅ Predictable data for assertions
- ✅ Fast test execution (transactions are faster than truncation)

## Helper Methods

### `reset_database`
Clears all tables and reloads seed data.

```ruby
reset_database
```

### `expect_no_errors`
Verifies the page loaded without exceptions.

```ruby
visit '/libraries'
expect_no_errors
```

### `count_table_rows`
Returns the number of records displayed in the table.

```ruby
expect(count_table_rows).to eq(Library.count)
```

## Writing New Tests

### Example: Testing a New Controller

```ruby
require 'spec_helper'

RSpec.describe 'YourModel CRUD', type: :feature do
  before(:each) do
    reset_database
  end

  describe 'Index page' do
    it 'displays all records' do
      visit '/your_models'
      expect_no_errors
      expect(page).to have_content('Your Models')
      expect(count_table_rows).to eq(YourModel.count)
    end
  end

  describe 'Creating a record' do
    it 'creates successfully' do
      visit '/your_models/new'

      fill_in 'your_model[name]', with: 'Test Name'
      click_button 'Create Your Model'

      expect(YourModel.count).to eq(1)
    end
  end

  describe 'Editing a record' do
    it 'updates successfully' do
      model = YourModel.first
      visit "/your_models/#{model.id}/edit"

      fill_in 'your_model[name]', with: 'Updated Name'
      click_button 'Save Changes'

      model.reload
      expect(model.name).to eq('Updated Name')
    end
  end

  describe 'Deleting a record' do
    it 'deletes successfully' do
      model = YourModel.create!(name: 'To Delete')
      visit '/your_models'

      within("[data-record-id='record_#{model.id}']") do
        click_link 'Delete'
      end

      expect(YourModel.exists?(model.id)).to be false
    end
  end
end
```

## Debugging Failed Tests

### View Page HTML
```ruby
it 'displays something' do
  visit '/libraries'
  puts page.html  # Print full HTML
  save_and_open_page  # Open in browser (requires launchy gem)
end
```

### Check for Errors
```ruby
it 'loads without errors' do
  visit '/libraries'
  expect(page).not_to have_content('Exception')
  expect(page).not_to have_content('Error')
  puts page.status_code  # Should be 200
end
```

### Inspect Database State
```ruby
it 'creates record' do
  puts Library.count  # Check count
  puts Library.last.inspect  # Check attributes
end
```

## Continuous Integration

To run tests in CI:

```bash
# Setup
bundle install
cd test/dummy_app
RAILS_ENV=test bundle exec rake db:create db:migrate db:seed
cd ../..

# Run tests
bundle exec rake spec
```

## Coverage Goals

- ✅ All CRUD routes work without errors
- ✅ All forms render correctly
- ✅ All custom field displays work
- ✅ All layout features render properly
- ✅ Database operations succeed
- ✅ Validations are enforced
- ✅ Relationships work correctly

## Troubleshooting

### Tests fail with "database is locked"
SQLite doesn't handle concurrent writes well. Ensure tests run sequentially:
```bash
bundle exec rspec --format documentation
```

### Tests fail with "record not found"
Database might not be seeded. Reset manually:
```bash
cd test/dummy_app
RAILS_ENV=test bundle exec rake db:reset
cd ../..
bundle exec rspec
```

### Tests pass locally but fail in CI
Ensure CI environment has all dependencies and proper Ruby version:
```yaml
# .github/workflows/test.yml example
- uses: ruby/setup-ruby@v1
  with:
    ruby-version: 3.2
    bundler-cache: true
```

## Contributing

When adding new features to ElaineCrud:
1. Write integration tests first (TDD)
2. Ensure all existing tests still pass
3. Add tests for edge cases
4. Update this README if needed

---

**Happy Testing! 🧪**
