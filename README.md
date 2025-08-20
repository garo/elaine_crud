# ElaineCrud

A Rails engine for rapidly generating CRUD interfaces for ActiveRecord models with minimal configuration.

## Features

- ✅ **Zero Configuration**: Works out of the box with any ActiveRecord model
- ✅ **Minimal Code**: Just specify model and permitted params
- ✅ **Modern UI**: Clean, responsive interface with TailwindCSS
- ✅ **Extensible**: Override any view or behavior in your host app
- ✅ **Rails Conventions**: Follows standard Rails patterns

## Installation

Add to your `Gemfile`:

```ruby
gem 'elaine_crud', path: '../elaine_crud'
```

Then run:
```bash
bundle install
```

## Quick Start

### 1. Create a Controller

```ruby
class PeopleController < ElaineCrud::BaseController
  layout 'application'  # Specify your app's layout
  
  model Person
  permit_params :name, :email, :phone, :active
end
```

### 2. Add Routes

```ruby
# config/routes.rb
resources :people
```

### 3. Configure TailwindCSS (Important!)

Add the gem's files to your `tailwind.config.js`:

```javascript
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    // Add this line to include ElaineCrud views
    '../elaine_crud/app/views/**/*.html.erb',
    '../elaine_crud/app/helpers/**/*.rb'
  ],
  // ... rest of your config
}
```

### 4. Restart Your Server

```bash
rails server
```

Navigate to `/people` and you'll have a fully functional CRUD interface!

## Usage

### Basic Controller

The minimal controller setup:

```ruby
class ArticlesController < ElaineCrud::BaseController
  layout 'application'  # Host app controls layout (header/footer/styling)
  
  model Article
  permit_params :title, :content, :published
end
```

### DSL Reference

- `model(ModelClass)` - Specify the ActiveRecord model to manage
- `permit_params(*attrs)` - Define permitted attributes for strong parameters
- `columns(config)` - (Future) Configure column display options

### Customization

#### Override Views

Create views in your app with the same names to override engine views:

```
app/views/articles/index.html.erb  # Overrides engine's index view
```

#### Override Controller Methods

```ruby
class ArticlesController < ElaineCrud::BaseController
  model Article
  permit_params :title, :content, :published
  
  private
  
  # Custom record fetching with scoping
  def fetch_records
    Article.published.order(:title)
  end
  
  # Custom column selection
  def determine_columns
    %w[title published created_at]
  end
end
```

#### Custom Helpers

Override the display helper in your application:

```ruby
# app/helpers/application_helper.rb
def display_column_value(record, column)
  case column
  when 'published'
    record.published? ? '📘 Published' : '📝 Draft'
  else
    super # Call the engine's helper
  end
end
```

## Requirements

- Rails 6.0+
- TailwindCSS (for styling)

## Examples

### Complete Example: Managing Blog Posts

```ruby
# app/controllers/posts_controller.rb
class PostsController < ElaineCrud::BaseController
  layout 'application'  # Use your app's layout
  
  model Post
  permit_params :title, :content, :published, :category_id
  
  private
  
  def fetch_records
    Post.includes(:category).order(created_at: :desc)
  end
end

# config/routes.rb
resources :posts

# Navigate to /posts for instant CRUD interface
```

### Example Output

The generated interface includes:
- **Index Page**: Responsive table with all records
- **Smart Formatting**: Dates, booleans, and nil values formatted nicely
- **Action Buttons**: Edit and Delete functionality
- **Empty States**: Helpful messages when no records exist
- **Modern Styling**: Clean TailwindCSS design

## Architecture

ElaineCrud follows a **separation of concerns** approach:

- **Engine provides**: CRUD logic, data formatting, content templates
- **Host app provides**: Layout, styling, HTML structure, navigation

### Layout Control

The gem doesn't impose any layout - your app controls the HTML structure:

```ruby
class UsersController < ElaineCrud::BaseController
  layout 'admin'        # Use admin layout
  # or layout 'public'  # Use public layout
  # or layout false     # No layout (API mode)
  
  model User
  permit_params :name, :email
end
```

This means:
- ✅ **Your app controls**: Headers, footers, navigation, CSS frameworks
- ✅ **Engine provides**: Table content, buttons, data formatting
- ✅ **Zero view files needed**: No templates to create in your app

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed technical documentation.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License. See [LICENSE](LICENSE) for details.