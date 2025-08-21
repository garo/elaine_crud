# CSS Grid Layout

ElaineCrud uses CSS Grid-based layouts for all CRUD views, providing flexible and responsive data display with support for field spanning similar to HTML table `colspan` and `rowspan` attributes.

## Overview

The system automatically:
- Calculates optimal grid columns based on field span configurations
- Encapsulates each ActiveRecord item in a `<div class="record">` with unique ID
- Supports both column and row spanning for flexible layouts
- Maintains inline editing capabilities within the grid structure

## Grid Span Configuration

Fields can span multiple columns and rows using the new grid configuration options:

### Column Spanning (similar to `colspan`)

```ruby
field :description do |f|
  f.title "Description"
  f.grid_column_span 2  # This field will span 2 columns
end

# Or using hash syntax:
field :description, 
  title: "Description",
  grid_column_span: 3  # This field will span 3 columns
```

### Row Spanning (similar to `rowspan`)

```ruby
field :large_content do |f|
  f.title "Large Content"
  f.grid_row_span 2  # This field will span 2 rows
end

# Or using hash syntax:
field :large_content,
  title: "Large Content", 
  grid_row_span: 2
```

### Combined Column and Row Spanning

```ruby
field :big_field do |f|
  f.title "Big Field"
  f.grid_column_span 2
  f.grid_row_span 2  # This field will span 2x2 grid cells
end
```

## Example Usage

```ruby
class DaycareBrowserController < ElaineCrud::BaseController
  model DaycareEntry
  
  field :date, title: "Entry Date"
  
  field :pupu_sleep, 
    title: "Pupu's Sleep",
    options: DaycareEntry::SLEEP_OPTIONS
  
  field :pupu_eat,
    title: "Pupu's Eating", 
    options: DaycareEntry::EAT_OPTIONS
  
  # Comments span 2 columns for more space
  field :pupu_comments do |f|
    f.title "Pupu Comments"
    f.grid_column_span 2
  end
  
  field :pentu_sleep,
    title: "Pentu's Sleep",
    options: DaycareEntry::SLEEP_OPTIONS
    
  field :pentu_eat,
    title: "Pentu's Eating",
    options: DaycareEntry::EAT_OPTIONS
  
  # Comments span 2 columns for more space  
  field :pentu_comments do |f|
    f.title "Pentu Comments"
    f.grid_column_span 2
  end
end
```

## How It Works

1. **Grid Container**: Each record is wrapped in a `<div class="record">` with a unique ID based on the ActiveRecord ID (`record_#{record.id}`)

2. **Dynamic Columns**: The grid automatically calculates the total number of columns needed based on field spans

3. **Responsive**: Uses CSS Grid with `minmax(0, 1fr)` for responsive behavior

4. **Inline Editing**: The grid layout supports inline editing just like the table layout

## Template Files

- `elaine_crud/base/index.html.erb` - Main grid-based index view
- `elaine_crud/base/_edit_row.html.erb` - Grid-based inline edit partial

## CSS Classes

The system automatically applies appropriate Tailwind CSS classes:
- `col-span-1` to `col-span-6` for column spanning
- `row-span-1` to `row-span-6` for row spanning

These classes are included in the Tailwind safelist to ensure they're available at runtime.

## Record Encapsulation

Each ActiveRecord item is encapsulated in a `<div class="record">` with a unique ID based on the ActiveRecord ID:

```html
<div class="record" id="record_123">
  <!-- Field grid layout here -->
</div>
```

This ensures proper isolation and targeting for JavaScript interactions or styling.