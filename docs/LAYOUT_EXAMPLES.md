# ElaineCrud Layout System

ElaineCrud now supports a flexible layout system that allows you to customize how ActiveRecord items are displayed in a grid format.

## Overview

The layout system introduces two main concepts:

1. **Layout Structure**: A nested array where the first dimension represents rows and the second dimension represents columns within each row
2. **Layout Header**: An array of configuration objects defining column widths, titles, and sorting behavior

## Default Behavior

By default, ElaineCrud displays all fields in a single row with equal column distribution:

```ruby
class PeopleController < ElaineCrud::BaseController
  model Person
  permit_params :name, :email, :bio, :status
  
  field :name, title: "Full Name"
  field :email, title: "Email Address"
  field :bio, title: "Biography"
  field :status, title: "Status"
end
```

This will create a layout like:
```
| Name (25%) | Email (25%) | Bio (25%) | Status (25%) |
```

## Custom Layouts

You can override the `calculate_layout` and `calculate_layout_header` methods to create custom layouts:

### Example 1: Two-Row Layout

```ruby
class PeopleController < ElaineCrud::BaseController
  model Person
  permit_params :name, :email, :bio, :status, :created_at
  
  field :name, title: "Full Name"
  field :email, title: "Email Address"  
  field :bio, title: "Biography"
  field :status, title: "Status"
  field :created_at, title: "Joined", visible: true
  
  private
  
  # Custom layout: Name and Email on first row, Bio and metadata on second row
  def calculate_layout(content, fields)
    [
      [
        { field_name: :name, colspan: 1 },
        { field_name: :email, colspan: 1 },
        { field_name: :status, colspan: 1 }
      ],
      [
        { field_name: :bio, colspan: 2 },
        { field_name: :created_at, colspan: 1 }
      ]
    ]
  end
  
  # Custom header: Define column sizes
  def calculate_layout_header(fields)
    ["25%", "35%", "25%", "15%"]  # 4 columns total
  end
end
```

### Example 2: Conditional Layout Based on Content

```ruby
class ProductController < ElaineCrud::BaseController
  model Product
  permit_params :name, :price, :description, :category, :image_url, :featured
  
  private
  
  # Different layouts for featured vs regular products
  def calculate_layout(content, fields)
    if content.featured?
      # Featured products get a prominent layout
      [
        [
          { field_name: :name, colspan: 2 },
          { field_name: :price, colspan: 1 }
        ],
        [
          { field_name: :description, colspan: 3 }
        ],
        [
          { field_name: :category, colspan: 1 },
          { field_name: :image_url, colspan: 2 }
        ]
      ]
    else
      # Regular products use compact layout
      [
        [
          { field_name: :name, colspan: 1 },
          { field_name: :price, colspan: 1 },
          { field_name: :category, colspan: 1 }
        ]
      ]
    end
  end
  
  def calculate_layout_header(fields)
    ["40%", "20%", "40%"]  # Flexible 3-column grid
  end
end
```

### Example 3: Complex Multi-Row Layout with Spans

```ruby
class OrderController < ElaineCrud::BaseController
  model Order
  permit_params :order_number, :customer_name, :total, :status, :notes, :created_at
  
  private
  
  def calculate_layout(content, fields)
    [
      [
        { field_name: :order_number, colspan: 1 },
        { field_name: :customer_name, colspan: 2 },
        { field_name: :total, colspan: 1 }
      ],
      [
        { field_name: :status, colspan: 1 },
        { field_name: :created_at, colspan: 1 },
        { field_name: :notes, colspan: 2 }  # Notes span 2 columns
      ]
    ]
  end
  
  def calculate_layout_header(fields)
    ["15%", "35%", "25%", "25%"]
  end
end
```

## Layout Configuration Properties

Each column configuration object in the layout can have the following properties:

- `field_name`: **Required** - The name of the field to display
- `colspan`: **Optional** - Number of columns this field should span (default: 1)
- `rowspan`: **Optional** - Number of rows this field should span (default: 1) 
- Future properties can be added as needed

## Method Signatures

### calculate_layout(content, fields)

- **content**: The ActiveRecord object for the current row
- **fields**: Array of field names that should be included in the layout
- **Returns**: Array of arrays, where each sub-array represents a row of column configurations

### calculate_layout_header(fields)

- **fields**: Array of field names that should be included in the layout  
- **Returns**: Array of header configuration objects with width, field_name, and/or title properties

## CSS Grid Integration

The layout system generates CSS Grid structures that automatically handle:

- Column sizing based on `calculate_layout_header`
- Column and row spanning based on layout configuration
- Responsive behavior using CSS Grid's built-in capabilities
- Proper alignment and spacing

## Migration from Existing Configurations

**Breaking Change**: The `grid_column_span` and `grid_row_span` field configuration options have been removed in favor of the more powerful layout system.

**Before (deprecated)**:
```ruby
field :bio, grid_column_span: 2
field :comments, grid_column_span: 3
```

**After (new layout system)**:
```ruby
private

def calculate_layout(content, fields)
  [
    [
      { field_name: :name, colspan: 1 },
      { field_name: :email, colspan: 1 },
      { field_name: :status, colspan: 1 }
    ],
    [
      { field_name: :bio, colspan: 2 },
      { field_name: :comments, colspan: 1 }
    ]
  ]
end

  def calculate_layout_header(fields)
    [
      { width: "25%", field_name: :name },     # Sortable column
      { width: "25%", field_name: :email },    # Sortable column  
      { width: "25%", title: "Personal Info" }, # Custom title, not sortable
      { width: "25%" }                         # Empty column
    ]
  end
```

This provides much more flexibility and control over your layouts.

## Header Configuration

Each header configuration object can contain:

- `width`: **Required** - CSS width value (e.g., "25%", "200px", "1fr")
- `field_name`: **Optional** - Field name to display and enable sorting
- `title`: **Optional** - Custom column title (overrides field title)

### Header Examples

```ruby
# Field-based sortable column
{ width: "30%", field_name: :name }

# Custom title with field sorting  
{ width: "25%", field_name: :created_at, title: "Created" }

# Custom title without field (not sortable)
{ width: "20%", title: "Category Info" }

# Empty header column
{ width: "10%" }
```

### Sorting Behavior

- **Sortable**: Columns with `field_name` get sorting links and indicators
- **Non-sortable**: Columns without `field_name` display plain text
- **Custom titles**: Use `title` to override the field's configured title

## Best Practices

1. **Keep it Simple**: Start with the default layout and only customize when you have specific layout requirements
2. **Consistent Headers**: Make sure your `calculate_layout_header` returns the right number of columns for your layout
3. **Responsive Design**: Use percentage or `fr` units in your header layout for responsive behavior
4. **Test Edge Cases**: Consider how your layout handles missing data or varying content lengths
5. **Performance**: The layout methods are called for every record, so keep them efficient

## Example Controller with Layout

Here's a complete example showing the layout system in action:

```ruby
class EventController < ElaineCrud::BaseController
  layout 'application'
  
  model Event
  permit_params :title, :description, :date, :location, :organizer, :capacity
  
  field :title, title: "Event Title"
  field :date, title: "Event Date"
  field :location, title: "Venue"
  field :organizer, title: "Organized By"
  field :capacity, title: "Max Attendees"
  field :description, title: "Description"
  
  private
  
  # Custom layout: Title and key info on top, description below
  def calculate_layout(content, fields)
    [
      [
        { field_name: :title, colspan: 2 },
        { field_name: :date, colspan: 1 },
        { field_name: :capacity, colspan: 1 }
      ],
      [
        { field_name: :organizer, colspan: 2 },
        { field_name: :location, colspan: 2 }
      ],
      [
        { field_name: :description, colspan: 4 }
      ]
    ]
  end
  
  def calculate_layout_header(fields)
    ["25%", "25%", "25%", "25%"]  # Equal 4-column grid
  end
end
```

This creates a structured layout that displays events in a clear, hierarchical format while maintaining the flexibility to customize for different types of content.