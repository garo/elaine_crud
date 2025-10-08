# ElaineCrud Demo Application

A fully functional demo application showcasing all features of the ElaineCrud gem through a **Library Management System**.

## Quick Start

### First Time Setup

```bash
# From the elaine_crud root directory
rake demo:setup
```

This will:
1. Create the SQLite database
2. Run all migrations
3. Seed the database with sample data

### Run the Demo

```bash
rake demo:server
```

Then open your browser to: **http://localhost:3000**

## Demo Application Overview

The demo models a complete library management system with realistic relationships and data.

### Domain Model

```
Library (3 records)
├── has_many :books (8 total)
├── has_many :members (6 total)
└── has_many :librarians (5 total)

Author (5 records)
└── has_many :books

Book (8 records)
├── belongs_to :author
├── belongs_to :library
└── has_many :loans

Member (6 records)
├── belongs_to :library
└── has_many :loans

Loan (4 records)
├── belongs_to :book
└── belongs_to :member

Librarian (5 records)
└── belongs_to :library
```

### Sample Data Included

- **3 Libraries**: Central City Library (NY), Riverside Library (OR), Oakwood Library (TX)
- **5 Authors**: Jane Austen, George Orwell, Toni Morrison, Haruki Murakami, Chimamanda Ngozi Adichie
- **8 Books**: Classic and contemporary literature with ISBNs, prices, and descriptions
- **6 Members**: Various membership types (Standard, Premium, Student, Senior)
- **4 Loans**: Different statuses (active, returned, overdue, pending)
- **5 Librarians**: Different roles (Manager, Assistant, Clerk, Archivist)

## Features Demonstrated

### 1. **Basic CRUD** (All Resources)
- ✅ Create, Read, Update, Delete operations
- ✅ Zero custom view code required
- ✅ Works out of the box

**Example**: Navigate to `/libraries` to see a full CRUD interface with just:
```ruby
class LibrariesController < ElaineCrud::BaseController
  layout 'application'
  model Library
  permit_params :name, :city, :state, :phone, :email, :established_date
end
```

---

### 2. **Foreign Key Relationships** (Books, Members, Loans, Librarians)

**Auto-detected and configured:**
- `Book` → `Author` and `Library`
- `Member` → `Library`
- `Loan` → `Book` and `Member`
- `Librarian` → `Library`

**What you get:**
- ✅ Dropdown selects in forms (automatically populated)
- ✅ Display names instead of IDs in index views
- ✅ N+1 query prevention (automatic `includes`)

**Try it**:
1. Go to `/books/new`
2. See Author and Library dropdowns automatically populated
3. Notice the form shows author names, not IDs

---

### 3. **Has-Many Relationships** (Libraries, Authors)

**Auto-detected:**
- Library shows counts of books, members, librarians
- Author shows count of books

**What you get:**
- ✅ Clickable counts: "5 books" links to filtered view
- ✅ Preview of related items
- ✅ Automatic eager loading

**Try it**:
1. Go to `/libraries`
2. Click on the book count for any library
3. See filtered view: `/books?library_id=1`

---

### 4. **Custom Field Display**

#### Currency Fields (Books, Librarians)
```ruby
field :price do |f|
  f.display_as { |value| number_to_currency(value) if value.present? }
end
```
**See it**: Book price shows as `$15.99` instead of `15.99`

#### Boolean Fields (Books, Authors, Members)
```ruby
field :available do |f|
  f.display_as { |value|
    if value
      content_tag(:span, '✓ Available', class: 'bg-green-100 text-green-800 ...')
    else
      content_tag(:span, '✗ Checked Out', class: 'bg-red-100 text-red-800 ...')
    end
  }
end
```
**See it**: Book availability shows as colored badges, not true/false

#### Date Formatting (Multiple Resources)
```ruby
field :established_date do |f|
  f.display_as { |value| value&.strftime("%B %Y") }
end
```
**See it**: Dates show as "June 1895" instead of "1895-06-15"

---

### 5. **Status Badges** (Loans)

Color-coded status indicators:
```ruby
field :status do |f|
  f.display_as lambda { |value, record|
    colors = {
      'pending' => 'gray',
      'active' => 'blue',
      'returned' => 'green',
      'overdue' => 'red'
    }
    color = colors[value] || 'gray'
    content_tag(:span, value.titleize,
      class: "px-2.5 py-0.5 rounded-full bg-#{color}-100 text-#{color}-800")
  }
end
```

**Try it**: Go to `/loans` to see color-coded loan statuses

---

### 6. **Dropdown Options** (Members, Loans, Librarians)

Predefined dropdown values:
```ruby
field :membership_type do |f|
  f.options ["Standard", "Premium", "Student", "Senior"]
end
```

**Try it**:
1. Go to `/members/new`
2. See membership type dropdown with predefined options

---

### 7. **Sorting** (All Resources)

- ✅ Click any column header to sort
- ✅ Click again to reverse direction
- ✅ Visual indicators (↑ ↓) for current sort
- ✅ Configurable default sort

```ruby
default_sort column: :name, direction: :asc
```

**Try it**: Click on any column header in any index view

---

### 8. **Inline Editing with Turbo** (All Resources)

- ✅ Click "Edit" to edit row inline
- ✅ No page reload
- ✅ Validation errors shown inline
- ✅ Cancel to revert changes

**Try it**:
1. Go to any index page (e.g., `/authors`)
2. Click "Edit" on any row
3. Make changes and save or cancel
4. Notice no page reload!

---

### 9. **Parent-Child Filtering** (Books by Library, Loans by Member)

URL-based filtering for has_many relationships:
- `/books?library_id=1` - Shows only books from Library #1
- `/loans?member_id=2` - Shows only loans for Member #2

**What you get:**
- ✅ Breadcrumb showing parent context
- ✅ Pre-populated foreign key when creating
- ✅ "Back to parent" links

**Try it**:
1. Go to `/libraries`
2. Click on the book count (e.g., "3 books")
3. See filtered book list with library context
4. Click "New Book" - library field is pre-selected!

---

### 10. **Email Links** (Libraries, Members, Librarians)

Auto-formatted mailto links:
```ruby
field :email do |f|
  f.display_as { |value| mail_to(value) if value.present? }
end
```

**Try it**: Click any email address in the index view

---

### 11. **Visibility Control** (Loans)

Override default column visibility:
```ruby
field :returned_at do |f|
  f.visible true  # Override default hiding of _at fields
end
```

**Default behavior**: Columns ending with `_at` are hidden unless explicitly shown

---

## Navigation Guide

### Main Resources (Top Navigation)

1. **Libraries** (`/libraries`)
   - Demonstrates: Basic CRUD, has_many relationships, email links, date formatting
   - Try: Click book/member counts to see filtered views

2. **Authors** (`/authors`)
   - Demonstrates: Boolean display, has_many books, biography text field
   - Try: Edit an author inline, toggle active status

3. **Books** (`/books`)
   - Demonstrates: Foreign keys (author, library), currency, availability badges
   - Try: Create a new book, see dropdown options

4. **Members** (`/members`)
   - Demonstrates: Dropdown options, date formatting, email links
   - Try: Change membership type via dropdown

5. **Loans** (`/loans`)
   - Demonstrates: Status badges, date highlighting, parent filtering
   - Try: Filter by member_id, observe overdue highlighting

6. **Librarians** (`/librarians`)
   - Demonstrates: Role dropdown, salary currency, hire date formatting
   - Try: Sort by salary, edit role inline

---

## Available Rake Tasks

```bash
# Display all demo information
rake demo:info

# Initial database setup
rake demo:setup

# Reset database with fresh data
rake demo:reset

# Start the demo server
rake demo:server

# Open Rails console
rake demo:console

# Open database console
rake demo:dbconsole
```

---

## Code Examples

### Minimal Controller (Libraries)
```ruby
class LibrariesController < ElaineCrud::BaseController
  layout 'application'
  model Library
  permit_params :name, :city, :state, :phone, :email, :established_date

  default_sort column: :name, direction: :asc

  field :email do |f|
    f.display_as { |value| mail_to(value) if value.present? }
  end
end
```
**Result**: Full CRUD interface with 10 lines of code!

---

### Advanced Controller (Books)
```ruby
class BooksController < ElaineCrud::BaseController
  layout 'application'
  model Book
  permit_params :title, :isbn, :publication_year, :pages, :description, :available, :price

  default_sort column: :title, direction: :asc

  # Currency formatting
  field :price do |f|
    f.title "Price"
    f.display_as { |value| number_to_currency(value) if value.present? }
  end

  # Boolean with badge
  field :available do |f|
    f.title "Availability"
    f.display_as { |value|
      if value
        content_tag(:span, '✓ Available',
          class: 'inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-green-100 text-green-800')
      else
        content_tag(:span, '✗ Checked Out',
          class: 'inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-red-100 text-red-800')
      end
    }
  end

  # Foreign keys auto-configured: author_id, library_id
  # Has-many loans auto-shown with count
end
```

---

### Status Badge Controller (Loans)
```ruby
class LoansController < ElaineCrud::BaseController
  layout 'application'
  model Loan
  permit_params :due_date, :returned_at, :status

  default_sort column: :due_date, direction: :desc

  # Colored status badges
  field :status do |f|
    f.title "Status"
    f.display_as lambda { |value, record|
      colors = {
        'pending' => 'gray',
        'active' => 'blue',
        'returned' => 'green',
        'overdue' => 'red'
      }
      color = colors[value] || 'gray'
      content_tag(:span, value.titleize,
        class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-#{color}-100 text-#{color}-800")
    }
    f.options ["pending", "active", "returned", "overdue"]
  end

  # Conditional styling for overdue dates
  field :due_date do |f|
    f.title "Due Date"
    f.display_as { |value, record|
      formatted = value&.strftime("%m/%d/%Y")
      if record.status == 'overdue'
        content_tag(:span, formatted, class: 'text-red-600 font-semibold')
      else
        formatted
      end
    }
  end

  # Show timestamp with time_ago
  field :returned_at do |f|
    f.title "Returned"
    f.visible true  # Override default hiding
    f.display_as { |value| value ? time_ago_in_words(value) + " ago" : "—" }
  end
end
```

---

## Architecture

```
test/dummy_app/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── libraries_controller.rb      # Basic CRUD + has_many
│   │   ├── authors_controller.rb        # Boolean fields
│   │   ├── books_controller.rb          # Foreign keys + currency
│   │   ├── members_controller.rb        # Dropdown options
│   │   ├── loans_controller.rb          # Status badges + filtering
│   │   └── librarians_controller.rb     # Roles + salary
│   ├── models/
│   │   ├── application_record.rb
│   │   ├── library.rb
│   │   ├── author.rb
│   │   ├── book.rb
│   │   ├── member.rb
│   │   ├── loan.rb
│   │   └── librarian.rb
│   └── views/
│       └── layouts/
│           └── application.html.erb     # Tailwind CSS layout
├── config/
│   ├── application.rb                   # Rails config
│   ├── database.yml                     # SQLite3
│   ├── routes.rb                        # Resource routes
│   └── environments/
├── db/
│   ├── migrate/                         # 6 migrations
│   └── seeds.rb                         # Rich sample data
└── bin/
    └── rails                            # Rails executable
```

---

## Customization Examples

### Override Record Fetching
```ruby
private
def fetch_records
  # Only show active books from current year
  Book.where(available: true)
      .where('publication_year >= ?', Date.current.year - 1)
      .includes(:author, :library)
end
```

### Override Column Selection
```ruby
private
def determine_columns
  %w[title author_id price available]
end
```

### Custom Layout
```ruby
def calculate_layout_header(fields)
  [
    { width: "40%", field_name: :title },
    { width: "20%", field_name: :author_id },
    { width: "15%", field_name: :price },
    { width: "15%", field_name: :available },
    { width: "10%", title: "Actions" }
  ]
end
```

---

## Technology Stack

- **Ruby**: 3.0+
- **Rails**: 7.0+
- **Database**: SQLite3
- **CSS**: Tailwind CSS (via CDN)
- **JavaScript**: Turbo (built into Rails)

---

## Troubleshooting

### Database Issues
```bash
# Reset everything
rake demo:reset
```

### Port Already in Use
```bash
# Stop the server (Ctrl+C) and run on different port
cd test/dummy_app
bin/rails server -p 3001
```

### Missing Dependencies
```bash
# From elaine_crud root
bundle install
```

---

## What to Look For

### 1. **Zero Boilerplate**
Notice how each controller is typically 15-30 lines including field configurations. No view files needed!

### 2. **Smart Defaults**
- Foreign keys auto-detected
- Has-many relationships auto-shown
- Sensible column visibility
- N+1 query prevention

### 3. **Easy Customization**
Every default behavior can be overridden with simple DSL methods.

### 4. **Modern UX**
- Inline editing with Turbo
- No page reloads
- Responsive design
- Clean Tailwind styling

---

## Running Integration Tests

The demo app includes a comprehensive integration test suite that validates all CRUD operations, custom layouts, and features.

### Test Setup

The test suite uses:
- **RSpec** - Testing framework
- **Capybara** - Browser simulation for integration testing
- **Database** - Automatically resets and seeds before tests

### Running Tests

```bash
# Run all integration tests
bundle exec rake spec

# Run only integration tests
bundle exec rake spec:integration

# Run tests for a specific controller
bundle exec rake spec:controller[libraries]
bundle exec rake spec:controller[books]
bundle exec rake spec:controller[members]
bundle exec rake spec:controller[librarians]

# Run a specific test file
bundle exec rspec spec/integration/books_crud_spec.rb

# Run tests with detailed output
bundle exec rspec spec/integration --format documentation
```

### Test Coverage

The integration test suite covers:

#### CRUD Operations (all controllers)
- ✅ Index page displays all records
- ✅ Index page shows correct field values
- ✅ Create new records via forms
- ✅ Edit existing records
- ✅ Delete records
- ✅ Form validation and error handling

#### Custom Layout Features
- ✅ Multi-row layout (Books with description on second row)
- ✅ Column spanning (colspan on description field)
- ✅ Flexible grid columns with minmax()
- ✅ Responsive horizontal scrolling
- ✅ Grid borders and styling

#### Field Display Customization
- ✅ Currency formatting ($19.99)
- ✅ Date formatting (January 15, 2024)
- ✅ Boolean badges (✓ Available / ✗ Checked Out)
- ✅ Email mailto links
- ✅ Dropdown options (roles, membership types)

#### Sorting and Filtering
- ✅ Default sort order (ascending by name/title)
- ✅ Sortable column headers with indicators
- ✅ Has-many relationship counts
- ✅ Relationship filtering

### Test Files

```
spec/
├── spec_helper.rb                    # RSpec configuration
├── support/
│   └── test_helpers.rb               # Helper methods for tests
└── integration/
    ├── libraries_crud_spec.rb        # Libraries CRUD tests
    ├── books_crud_spec.rb            # Books CRUD tests (with multi-row layout)
    ├── members_crud_spec.rb          # Members CRUD tests (with dropdowns)
    ├── librarians_crud_spec.rb       # Librarians CRUD tests (with currency)
    ├── layout_features_spec.rb       # Custom layout feature tests
    └── sorting_and_filtering_spec.rb # Sorting and filtering tests
```

### Example Test Output

```
Libraries CRUD
  Index page
    ✓ displays all libraries
    ✓ displays library details correctly
    ✓ has New Library link
  Creating a library
    ✓ shows new library form
    ✓ creates a new library successfully
  Editing a library
    ✓ shows edit library form
    ✓ updates library successfully
  Deleting a library
    ✓ deletes library successfully

Finished in 2.34 seconds (files took 1.2 seconds to load)
8 examples, 0 failures
```

### Continuous Integration

The test suite is designed to:
- Reset the database to a clean state before each test run
- Use database transactions to isolate tests
- Verify all routes work without errors
- Ensure data integrity after CRUD operations
- Validate custom field displays and layouts

---

## Next Steps

1. **Explore the UI**: Click around and try all the features
2. **Run the Tests**: Verify everything works with `bundle exec rake spec`
3. **Read the Code**: Check `test/dummy_app/app/controllers/` for examples
4. **Modify Data**: Use the console to add your own records
5. **Customize**: Try changing field configurations and see the results
6. **Integrate**: Use this as a reference for your own ElaineCrud projects

---

## Additional Resources

- **Main Documentation**: See `/docs` folder for detailed feature documentation
- **API Reference**: `ELAINE_CRUD_API_DOCUMENTATION.md` in project root
- **Source Code**: All controllers in `test/dummy_app/app/controllers/`
- **Test Suite**: Integration tests in `spec/integration/`

---

**Happy Exploring! 🎉**
