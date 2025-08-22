# Foreign Key Support in ElaineCrud

ElaineCrud now provides comprehensive automatic support for `belongs_to` relationships in ActiveRecord models. This feature eliminates the need for manual configuration in most cases while still providing flexibility for customization.

## Features

### Automatic Detection
- Automatically detects all `belongs_to` relationships in your ActiveRecord model
- Auto-configures foreign key fields without requiring manual setup
- Includes foreign keys in permitted parameters automatically
- Optimizes database queries with automatic `includes()` to prevent N+1 queries

### Smart Display Field Detection
- Automatically determines the best display field for related models
- Prefers common fields like `:name`, `:title`, `:display_name`, `:full_name`, `:label`, `:description`
- Falls back to first string/text column if common fields aren't found
- Uses `:id` as final fallback

### Display Behavior
- **Index View**: Shows the related record's display field instead of the foreign key ID
- **Edit Forms**: Renders a dropdown with all available options from the related model, with the current value pre-selected
- **Error Handling**: Gracefully handles missing records and configuration errors

## Basic Usage

```ruby
class MeetingsController < ElaineCrud::BaseController
  model Meeting  # Automatically detects belongs_to :meeting_room
  permit_params :title, :start_time, :end_time  # meeting_room_id included automatically
end
```

That's it! ElaineCrud will automatically:
1. Detect the `belongs_to :meeting_room` relationship
2. Configure `meeting_room_id` as a foreign key field
3. Show meeting room names in the index instead of IDs
4. Provide a dropdown in forms with all meeting rooms
5. Include `meeting_room_id` in permitted parameters

## Customization Options

### Basic Customization
```ruby
field :meeting_room_id do
  title "Conference Room"
  foreign_key(
    model: MeetingRoom,
    display: :name,
    null_option: "Choose a room"
  )
end
```

### Advanced Display Logic
```ruby
field :meeting_room_id do
  foreign_key(
    model: MeetingRoom,
    display: ->(room) { "#{room.name} (#{room.capacity} seats)" }
  )
end
```

### Scoped Options
```ruby
field :meeting_room_id do
  foreign_key(
    model: MeetingRoom,
    display: :name,
    scope: -> { MeetingRoom.available.order(:name) }
  )
end
```

### Custom Method Display
```ruby
# In MeetingRoom model
class MeetingRoom < ApplicationRecord
  def display_name
    "#{name} - #{building.name}"
  end
end

# In controller
field :meeting_room_id do
  foreign_key(
    model: MeetingRoom,
    display: :display_name
  )
end
```

## Configuration Options

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| `model` | Class | The related ActiveRecord model | Auto-detected from belongs_to |
| `display` | Symbol/Proc | Field or method to display | Auto-detected (name, title, etc.) |
| `scope` | Proc | Limits available options | `-> { Model.all }` |
| `null_option` | String | Placeholder text for blank option | "Select [relationship name]" |

## Implementation Details

### Automatic Model Analysis
When you call `model ModelClass`, ElaineCrud:
1. Inspects all `belongs_to` reflections on the model
2. Creates `FieldConfiguration` objects for each foreign key
3. Determines the best display field for each related model
4. Adds foreign keys to the permitted parameters list

### Query Optimization
The `fetch_records` method automatically includes belongs_to associations to prevent N+1 queries:
```ruby
# Instead of this (N+1 queries):
meetings.each { |meeting| puts meeting.meeting_room.name }

# ElaineCrud automatically does this:
Meeting.includes(:meeting_room).each { |meeting| puts meeting.meeting_room.name }
```

### Display Field Detection Logic
1. Check for common display fields: `name`, `title`, `display_name`, `full_name`, `label`, `description`
2. If none found, use first string/text column (excluding id, created_at, updated_at)
3. Fall back to `:id` if no suitable field found

## Error Handling

ElaineCrud handles various error scenarios gracefully:
- **Missing Related Record**: Shows "Not found (ID: X)" message
- **Configuration Errors**: Shows error message in development, falls back to ID in production
- **Missing Display Field**: Falls back to `to_s` method
- **Database Errors**: Gracefully handles and logs errors

## Migration from Manual Configuration

If you previously configured foreign keys manually, ElaineCrud will respect your existing configuration:
```ruby
# Your existing configuration takes precedence
field :meeting_room_id do
  foreign_key(model: MeetingRoom, display: :custom_name)
end
# Auto-detection skips this field since it's already configured
```

## Performance Considerations

- **Automatic Includes**: Foreign key relationships are automatically included in queries
- **Lazy Loading**: Related records are only loaded when actually displayed
- **Caching**: Consider adding Rails caching for frequently accessed dropdown options

## Future Enhancements

The current implementation focuses on `belongs_to` relationships. Future versions may include:
- `has_many` relationship support
- `has_and_belongs_to_many` relationship support
- Polymorphic relationship support
- Search/autocomplete for large datasets
- Nested attribute support

## Example Models

```ruby
class Meeting < ApplicationRecord
  belongs_to :meeting_room
  belongs_to :organizer, class_name: 'User'
  
  validates :title, presence: true
end

class MeetingRoom < ApplicationRecord
  has_many :meetings
  validates :name, presence: true
end

class User < ApplicationRecord
  has_many :organized_meetings, class_name: 'Meeting', foreign_key: 'organizer_id'
end
```

With these models, ElaineCrud automatically handles both `meeting_room_id` and `organizer_id` foreign keys in your `MeetingsController`.

## Troubleshooting

### Foreign Key Not Showing as Dropdown
- Ensure your model has a `belongs_to` relationship defined
- Check that the foreign key column exists in the database
- Verify the related model class is accessible

### Wrong Display Field Being Used
- Manually configure the `display` option in field configuration
- Add a custom display method to your model
- Check model column names match expected patterns

### Performance Issues
- Add database indexes on foreign key columns
- Consider using scopes to limit dropdown options
- Implement caching for frequently accessed dropdowns