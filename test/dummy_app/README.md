# ElaineCrud Demo Application

This is a fully functional demo application showcasing all features of the ElaineCrud gem.

## Domain: Library Management System

The demo models a library management system with the following entities:

- **Libraries** - Parent entity with has_many relationships
- **Authors** - Writers with books
- **Books** - Core entity with foreign keys and pricing
- **Members** - Library patrons with membership types
- **Loans** - Junction table with status tracking
- **Librarians** - Staff with roles and salaries

## Features Demonstrated

### 1. Basic CRUD Operations
All resources have full Create, Read, Update, Delete functionality with zero custom view code.

### 2. Foreign Key Relationships (belongs_to)
- **Auto-detected**: Book → Author, Book → Library, Member → Library
- **Dropdown rendering**: Foreign keys automatically show as dropdowns in forms
- **Display names**: Shows related record names instead of IDs in index views

### 3. Has-Many Relationships
- **Auto-detected counts**: Library shows count of books, members, librarians
- **Clickable links**: Click count to view filtered records
- **Parent filtering**: `/books?library_id=1` shows only books from that library

### 4. Custom Field Display
- **Currency**: Book price, Librarian salary formatted as currency
- **Dates**: Various date formatting (established_date, hire_date, joined_at)
- **Booleans**: Custom icons and colors for active/available fields
- **Status badges**: Loan status with colored Tailwind badges

### 5. Dropdown Options
- **Membership types**: Standard, Premium, Student, Senior
- **Loan status**: pending, active, returned, overdue
- **Librarian roles**: Manager, Assistant, Clerk, Archivist

### 6. Sorting
- **Default sorts**: Each controller has sensible default sorting
- **Clickable headers**: Sort by any column in the index view
- **Direction toggle**: Click again to reverse sort direction

### 7. Inline Editing (Turbo)
- **Row-level editing**: Click Edit to edit inline without page reload
- **Validation**: Shows errors inline
- **Cancel**: Revert changes without saving

## Quick Start

### From the elaine_crud root directory:

```bash
# First time setup
rake demo:setup

# Run the server
rake demo:server

# Visit http://localhost:3000
```

### Rake Tasks

```bash
rake demo          # Show demo information
rake demo:setup    # Initial setup (create, migrate, seed)
rake demo:reset    # Reset database with fresh data
rake demo:server   # Start the Rails server
rake demo:console  # Open Rails console
rake demo:info     # Display demo information
```

## Exploring the Code

### Controller Examples

Each controller demonstrates different features:

**LibrariesController** (`app/controllers/libraries_controller.rb`)
- Basic CRUD with minimal configuration
- Custom email display with mailto links
- Date formatting
- Has-many relationships

**BooksController** (`app/controllers/books_controller.rb`)
- Foreign key dropdowns (author_id, library_id)
- Currency formatting for price
- Boolean display for availability
- Custom badge styling

**LoansController** (`app/controllers/loans_controller.rb`)
- Status badges with colors
- Date-based conditional styling (overdue highlighting)
- Parent filtering support
- Dropdown options for status

**MembersController** (`app/controllers/members_controller.rb`)
- Dropdown options (membership_type)
- Email with mailto links
- Date formatting
- Boolean active status

## Architecture

```
test/dummy_app/
├── app/
│   ├── controllers/      # 6 ElaineCrud controllers
│   ├── models/           # 6 ActiveRecord models
│   └── views/
│       └── layouts/      # Application layout only
├── config/
│   ├── application.rb    # Rails app config
│   ├── database.yml      # SQLite3 configuration
│   ├── routes.rb         # Resource routes
│   └── environments/     # Dev/test configs
└── db/
    ├── migrate/          # 6 migration files
    └── seeds.rb          # Sample data
```

## Database Schema

### Libraries
- name, city, state, phone, email, established_date

### Authors
- name, biography, birth_year, country, active

### Books
- title, isbn, publication_year, pages, description, available, price
- Foreign keys: author_id, library_id

### Members
- name, email, phone, membership_type, joined_at, active
- Foreign key: library_id

### Loans
- due_date, returned_at, status
- Foreign keys: book_id, member_id

### Librarians
- name, email, role, hire_date, salary
- Foreign key: library_id

## Sample Data

The seed data includes:
- 3 Libraries (New York, Portland, Austin)
- 5 Authors (classic and contemporary)
- 8 Books (diverse selection)
- 6 Members (across all libraries)
- 4 Loans (various statuses)
- 5 Librarians (different roles)

## Customization Examples

### Override a Controller Method

```ruby
class BooksController < ElaineCrud::BaseController
  # ... field configurations ...

  private

  def fetch_records
    # Only show available books
    Book.available.includes(:author, :library)
  end
end
```

### Add Custom Field Display

```ruby
field :price do |f|
  f.display_as { |value| number_to_currency(value) }
end
```

### Configure Foreign Key

```ruby
field :author_id do |f|
  f.foreign_key(
    model: Author,
    display: :name,
    scope: -> { Author.active.order(:name) }
  )
end
```

## Testing

This demo app can also serve as an integration test environment:

```bash
cd test/dummy_app
rails test  # (when test files are added)
```

## Requirements

- Ruby 3.0+
- Rails 7.0+
- SQLite3
- TailwindCSS (loaded via CDN in demo)

## License

This demo application is part of the ElaineCrud gem and is released under the MIT License.
