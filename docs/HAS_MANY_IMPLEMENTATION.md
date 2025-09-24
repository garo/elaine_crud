# has_many Relationship Implementation

This document describes the implementation of `has_many` relationship support in ElaineCrud using filtered flat resources (URLs like `/meetings?meeting_room_id=4`).

## Implementation Summary

The has_many implementation adds the following features:

### 1. Automatic Detection
- ElaineCrud automatically detects all `has_many` relationships in your ActiveRecord models
- Auto-configures display fields for related records
- Includes automatic query optimization with `includes()` to prevent N+1 queries

### 2. Parent Filtering
- Supports URLs like `/meetings?meeting_room_id=4` to show filtered views
- Automatically filters records based on parent relationship parameters
- Maintains parent context in forms and redirects

### 3. Smart Display
- **Index Views**: Shows relationship summaries with counts and previews
- **Links**: Automatically generates links to filtered views (e.g., "5 meetings: Daily Standup, Team Review...")
- **Forms**: Pre-populates parent relationships when creating from filtered context

### 4. UI Enhancements
- Context-aware breadcrumbs showing the parent record
- "View All" links to remove filters
- Parent information display in forms

## Usage Examples

### Automatic Configuration (No Code Required)

```ruby
class MeetingRoomsController < ElaineCrud::BaseController
  model MeetingRoom
  permit_params :name, :capacity, :building
  # has_many :meetings relationship automatically detected and configured
end

class MeetingsController < ElaineCrud::BaseController
  model Meeting
  permit_params :title, :start_time, :end_time, :meeting_room_id
  # Automatic parent filtering support - no additional configuration needed
end
```

### Manual Configuration (Optional)

```ruby
class MeetingRoomsController < ElaineCrud::BaseController
  model MeetingRoom
  permit_params :name, :capacity, :building
  
  # Optional: Customize has_many relationship display
  has_many_relation :meetings do
    title "Room Meetings"
    display :title
    show_count true
    max_preview_items 3
    scope -> { where('start_time > ?', Time.current) }
  end
end
```

## Generated URLs and Behavior

```ruby
# MeetingRoom index page shows:
# Name        | Capacity | Meetings
# Room A      | 20       | 5 meetings: Daily Standup, Team Review, All Hands
# Room B      | 10       | 2 meetings: 1:1 Meeting, Code Review
```

Clicking "5 meetings: Daily Standup, Team Review..." generates:
- URL: `/meetings?meeting_room_id=4`
- Shows filtered view with context banner
- "New Meeting" button pre-populates `meeting_room_id=4`
- After creating, redirects back to filtered view

## Technical Implementation

### Controller Changes
- **BaseController**: Added parent filtering logic in `fetch_records`
- **Auto-detection**: `auto_configure_has_many_relationships` method
- **Context management**: `@parent_context` instance variable for UI
- **Query optimization**: Enhanced `get_all_relationship_includes`

### Field Configuration
- **FieldConfiguration**: Added `has_many_config` attribute and methods
- **Display logic**: `render_has_many_display` method for relationship summaries
- **DSL support**: Block-style configuration with `has_many_relation`

### Helper Methods
- **BaseHelper**: Enhanced `display_field_value` to handle has_many
- **Link generation**: Automatic URL generation for filtered views
- **Relationship detection**: `is_has_many_relationship?` helper

### View Templates
- **Index**: Parent context banner with breadcrumbs
- **Forms**: Hidden fields and context information for parent relationships
- **Styling**: TailwindCSS classes for consistent UI

## Configuration Options

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| `display` | Symbol/Proc | Field or method to display | Auto-detected (name, title, etc.) |
| `show_count` | Boolean | Show count in relationship display | `true` |
| `max_preview_items` | Integer | Number of items to preview | `3` |
| `scope` | Proc | Limits displayed relationships | `-> { all }` |
| `foreign_key` | Symbol | The foreign key field name | Auto-detected |

## Supported URL Patterns

```ruby
# All supported URL patterns:
/meeting_rooms                           # All meeting rooms
/meeting_rooms/4                        # Show specific meeting room
/meetings                               # All meetings  
/meetings?meeting_room_id=4             # Meetings filtered by room
/meetings/new                           # Create new meeting
/meetings/new?meeting_room_id=4         # Create meeting for specific room
/meetings/123?meeting_room_id=4         # Show meeting in room context
```

## Migration from Manual Configuration

If you previously configured has_many relationships manually, ElaineCrud respects existing configurations:

```ruby
# Your existing configuration takes precedence
has_many_relation :meetings do
  display :custom_title
  show_count false
end
# Auto-detection skips this field since it's already configured
```

## Performance Considerations

- **Automatic Includes**: Related models are automatically included in queries
- **Lazy Loading**: Relationship counts and previews are loaded only when displayed
- **Query Optimization**: Uses single queries with joins rather than N+1 patterns
- **Caching**: Consider adding Rails caching for frequently accessed relationship displays

## Error Handling

ElaineCrud handles various error scenarios gracefully:
- **Missing Parent Record**: Shows error message with record ID
- **Configuration Errors**: Falls back to basic display in production
- **Missing Display Fields**: Uses fallback display methods
- **Database Errors**: Logs errors and shows user-friendly messages

This implementation provides a powerful, automatic has_many relationship system that works out-of-the-box while still allowing for extensive customization when needed.