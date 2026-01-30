# ElaineCrud Architecture Documentation

## Overview

ElaineCrud is a Ruby gem that provides a Rails Engine for rapidly generating CRUD (Create, Read, Update, Delete) interfaces for ActiveRecord models. The gem follows Rails conventions and provides a minimal, ergonomic DSL for creating database admin interfaces with zero boilerplate.

## Design Goals

- **Minimal Configuration**: Developers should only need to specify the model and permitted attributes
- **Convention over Configuration**: Follow Rails patterns and conventions
- **Non-Mountable Engine**: Integrate seamlessly with host applications without namespace isolation
- **Zero External Dependencies**: Only depend on Rails itself
- **Customizable**: Allow host applications to override views and behavior
- **Modern UI**: Provide clean, responsive interfaces using TailwindCSS

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Host Rails App                           │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              Custom Controller                            │  │
│  │  class PeopleController < ElaineCrud::BaseController      │  │
│  │    model Person                                           │  │
│  │    permit_params :name, :email                           │  │
│  │  end                                                      │  │
│  └───────────────────────────────────────────────────────────┘  │
│                               │                                 │
│                               ▼                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   Routes                                  │  │
│  │  resources :people                                        │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ElaineCrud Engine                          │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                 BaseController                            │  │
│  │  • Model introspection                                   │  │
│  │  • Standard CRUD actions                                 │  │
│  │  • Strong parameters                                     │  │
│  │  • Column detection                                      │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                 Default Views                             │  │
│  │  • Index listing with table                              │  │
│  │  • Smart column formatting                               │  │
│  │  • Action buttons (Edit, Delete)                         │  │
│  │  • TailwindCSS styling                                   │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   Helpers                                 │  │
│  │  • Column value formatting                               │  │
│  │  • Boolean/Date display logic                            │  │
│  │  • Truncation and styling                                │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## File Structure

```
elaine_crud/
├── elaine_crud.gemspec          # Gem specification
├── Gemfile                      # Development dependencies
├── lib/
│   ├── elaine_crud.rb          # Main gem entry point
│   └── elaine_crud/
│       ├── version.rb          # Version constant
│       └── engine.rb           # Rails Engine configuration
├── app/
│   ├── controllers/
│   │   └── elaine_crud/
│   │       └── base_controller.rb    # Core CRUD controller logic
│   ├── helpers/
│   │   └── elaine_crud/
│   │       └── base_helper.rb        # View helper methods
│   └── views/
│       └── elaine_crud/
│           └── base/
│               └── index.html.erb    # Default index view template
└── docs/
    └── ARCHITECTURE.md         # This documentation file
```

## Core Components

### 1. Engine Configuration (`lib/elaine_crud/engine.rb`)

The Rails Engine is configured as **non-mountable** to integrate seamlessly with host applications:

```ruby
module ElaineCrud
  class Engine < ::Rails::Engine
    # Non-mountable engine - do not call isolate_namespace
    
    # Make app directories available to autoloader
    config.autoload_paths << File.expand_path('../../app/controllers', __dir__)
    config.autoload_paths << File.expand_path('../../app/helpers', __dir__)
    
    # Add views to Rails view path
    initializer 'elaine_crud.append_view_paths' do |app|
      ActiveSupport.on_load :action_controller do
        append_view_path File.expand_path('../../app/views', __dir__)
      end
    end
    
    # Include helpers globally
    initializer 'elaine_crud.include_helpers' do
      ActiveSupport.on_load :action_controller do
        include ElaineCrud::BaseHelper
      end
    end
  end
end
```

**Key Design Decisions:**
- No `isolate_namespace` call ensures classes are available in global namespace
- Autoload paths ensure proper class loading
- View paths are appended, allowing host app views to override engine views
- Helpers are included globally for maximum compatibility

### 2. BaseController (`app/controllers/elaine_crud/base_controller.rb`)

The heart of the gem, providing a DSL and CRUD functionality:

```ruby
class ElaineCrud::BaseController < ActionController::Base
  # No layout specified - host app controllers set their own layout
  
  # Class-level configuration
  class_attribute :crud_model, :permitted_attributes, :column_configurations
  
  # DSL Methods
  class << self
    def model(model_class)
      self.crud_model = model_class
    end
    
    def permit_params(*attrs)
      self.permitted_attributes = attrs
    end
    
    def columns(config = {})
      self.column_configurations = config
    end
  end
  
  # Standard CRUD actions: index, show, new, create, edit, update, destroy
end
```

**Features:**
- **Layout Agnostic**: No layout specified, host app controls HTML structure
- **Model Introspection**: Automatically detects columns and relationships
- **Strong Parameters**: Uses configured permitted attributes
- **Column Detection**: Filters out ID and timestamp columns by default
- **Extensible**: Subclasses can override any method for custom behavior

### 3. View Helpers (`app/helpers/elaine_crud/base_helper.rb`)

Smart formatting for different data types:

```ruby
def display_column_value(record, column)
  value = record.public_send(column)
  
  case value
  when nil
    content_tag(:span, '—', class: 'text-gray-400')
  when true
    content_tag(:span, '✓', class: 'text-green-600 font-bold')
  when false
    content_tag(:span, '✗', class: 'text-red-600 font-bold')
  when Date, DateTime, Time
    value.strftime('%m/%d/%Y')
  else
    truncate(value.to_s, length: 50)
  end
end
```

**Features:**
- **Type-Aware Formatting**: Different display logic for booleans, dates, nil values
- **Consistent Styling**: Uses TailwindCSS classes for visual consistency
- **Truncation**: Prevents long text from breaking table layout

### 4. Default Views (`app/views/elaine_crud/base/index.html.erb`)

Modern, responsive table interface:

```erb
<div class="container mx-auto px-4 py-8">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold text-gray-900"><%= @model_name.pluralize %></h1>
    <%= link_to "New #{@model_name}", url_for(action: :new), 
        class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" %>
  </div>

  <% if @records.any? %>
    <!-- Responsive table with TailwindCSS styling -->
  <% else %>
    <!-- Empty state with call-to-action -->
  <% end %>
</div>
```

**Features:**
- **Responsive Design**: Works on mobile and desktop
- **TailwindCSS Styling**: Modern, clean appearance
- **Empty States**: Helpful messaging when no records exist
- **Action Buttons**: Edit and Delete functionality

## TailwindCSS Integration

ElaineCrud ships with precompiled CSS that includes all necessary TailwindCSS classes. Host applications simply need to include the stylesheet in their layout:

```erb
<%= stylesheet_link_tag "elaine_crud", "data-turbo-track": "reload" %>
```

This approach ensures the gem works without requiring the host application to configure TailwindCSS scanning or safelisting.

## Design Philosophy

### Separation of Concerns

The gem follows a clean separation between content and presentation:
- **Engine provides**: CRUD logic, data formatting, content templates
- **Host app provides**: Layout, styling, HTML structure, navigation
- **Host app controls**: Headers, footers, CSS frameworks, page structure

### Convention over Configuration

The gem follows Rails conventions wherever possible:
- Standard CRUD action names
- RESTful routing patterns
- ActiveRecord assumptions
- Rails view helper patterns

### Minimal API Surface

The DSL is intentionally small:
- `model` - specify the ActiveRecord class
- `permit_params` - define strong parameters
- `layout` - host app specifies which layout to use
- `columns` - (future) customize column display

### Extensibility

Host applications can override any behavior:
- Views override engine views by Rails precedence
- Controller methods can be overridden in subclasses
- Helpers can be customized or extended
- Layout and styling completely controlled by host app

### Zero Configuration Default

The gem works with zero configuration for basic use cases:
- Automatic column detection
- Sensible defaults for display formatting
- Standard CRUD operations out of the box