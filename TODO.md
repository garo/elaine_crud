# ElaineCrud TODO

This document tracks planned features and enhancements for ElaineCrud.

## Current Status

### ✅ Completed Features

1. **Core CRUD Functionality**
   - Basic CRUD actions (index, show, new, create, edit, update, destroy)
   - Standard RESTful routing
   - Strong parameters support
   - TailwindCSS styling

2. **Sorting**
   - Clickable column headers
   - Ascending/descending sort
   - URL parameter persistence (`?sort=name&direction=asc`)
   - Visual indicators (↑↓) for sort direction

3. **Pagination**
   - Kaminari integration
   - Per-page selection (10, 25, 50, 100)
   - URL parameter support (`?page=2&per_page=25`)
   - Page navigation with context preservation

4. **Field Configuration DSL**
   - `field` DSL for customizing field behavior
   - Custom titles and descriptions
   - `display_as` callbacks for custom rendering
   - `edit_as` callbacks for custom form fields
   - Dropdown options support
   - Readonly fields
   - Default values

5. **Foreign Key Support (belongs_to)**
   - Automatic detection via ActiveRecord reflections
   - Auto-configured dropdowns in forms
   - Smart display field detection
   - Custom display callbacks
   - Scoped options
   - Null option placeholders
   - N+1 query prevention with automatic includes

6. **has_many Relationship Support**
   - Automatic detection and configuration
   - Display with counts and previews (e.g., "5 items: Item 1, Item 2...")
   - Clickable links to filtered views (`/items?parent_id=4`)
   - Parent context preservation in forms
   - Readonly in edit forms
   - N+1 query prevention
   - Context-aware breadcrumbs
   - Auto-population of parent relationship when creating from filtered view

7. **has_one Relationship Support**
   - Automatic detection and configuration
   - Display related record's display field
   - Shows "—" placeholder for nil relationships
   - Readonly in edit forms
   - N+1 query prevention with automatic includes
   - Smart display field selection

8. **Turbo Frame Support**
   - Inline editing without full page reload
   - Edit and cancel actions via Turbo Frames
   - Seamless UX with partial updates
   - Fallback to full page navigation when disabled

9. **CSS Grid Layout System**
   - Responsive grid-based table layout
   - Custom column width configuration
   - `calculate_layout_header` override for custom sizing
   - Handles varying content sizes gracefully

10. **Integration Testing**
    - RSpec integration tests for all major features
    - Test coverage for CRUD operations
    - Relationship testing
    - Layout and UI testing

11. **has_and_belongs_to_many (HABTM) Support**
    - Minimal infrastructure approach for maximum flexibility
    - Automatic detection via ActiveRecord reflections
    - Minimal default display (comma-separated list)
    - Checkbox form rendering with scrollable container
    - Automatic parameter permitting for `*_ids` arrays
    - N+1 query prevention with automatic includes
    - Application-level customization via `display_as` callbacks
    - Generic implementation (works for any HABTM: Students ↔ Courses, Users ↔ Roles, etc.)
    - Fixed empty checkbox submission with hidden field pattern
    - All variable naming is generic (no use-case specific hardcoding)

---

## 🚧 Planned Features

### High Priority

#### 1. Search/Filtering
**Description**: Add search and filtering capabilities to find specific records

**Features**:
- Global text search across displayed columns
- Per-column filtering (status, categories, date ranges)
- URL parameter support (`?search=term`, `?filter[status]=active`)
- Clear filters button
- Search persistence across pagination
- Highlight search terms in results (optional)

**Benefits**:
- Essential for admin interfaces with large datasets
- Works naturally with existing sorting and pagination
- High user value for finding specific records

**Implementation Notes**:
- Add search form to index view
- Extend `fetch_records` to apply search conditions
- URL parameter handling similar to sort/pagination
- Consider using `ransack` gem or custom implementation

---

#### 2. Validation Error Display
**Description**: Improve form validation error handling and display

**Features**:
- Inline field-level error messages
- Summary of errors at top of form
- Highlight invalid fields with red borders
- Preserve form data on validation failure
- Error messages for custom validations

**Benefits**:
- Better UX for form submissions
- Clear feedback on what needs to be fixed
- Professional error handling

**Implementation Notes**:
- Enhance new/edit form templates
- Add error styling with TailwindCSS
- Helper methods for error rendering
- Test with various validation scenarios

---

### Medium Priority


#### 3. Bulk Actions
**Description**: Enable operations on multiple records at once

**Features**:
- Checkbox selection for records
- "Select All" / "Select None" options
- Bulk delete with confirmation
- Bulk status/field updates
- Custom bulk actions via DSL
- Progress feedback for long operations

**Benefits**:
- Common admin interface pattern
- Efficiency for managing many records
- Reduces repetitive actions

**Implementation Notes**:
- Add checkboxes to index view
- JavaScript for selection handling
- Bulk action dropdown/buttons
- Confirmation dialogs
- Consider using Turbo Streams for updates

---

#### 4. Advanced Column Configuration
**Description**: Enhance column display and customization options

**Features**:
- Column visibility toggles (show/hide)
- Column reordering (drag & drop or preferences)
- Sticky columns for horizontal scrolling
- Column grouping/categories
- Per-user column preferences (requires user model)
- Export column configuration

**Benefits**:
- Handle tables with many columns
- Customizable views for different users/roles
- Better UX for wide tables

---

### Low Priority

#### 5. Export Functionality
**Description**: Export records to various formats

**Features**:
- Export to CSV, JSON, Excel (XLSX)
- Respects current filters, search, and sorting
- Configurable column selection for export
- Background job support for large exports
- Email delivery for large files

**Benefits**:
- Data portability
- Reporting and analysis
- Integration with external tools

**Implementation Notes**:
- CSV: Built-in Ruby CSV library
- Excel: Use `caxlsx` or `spreadsheet` gem
- JSON: Built-in Rails support
- Consider streaming for large datasets
- Add export buttons to index view

---

#### 6. Import Functionality
**Description**: Bulk import records from files

**Features**:
- CSV/Excel file upload
- Column mapping interface
- Validation and error reporting
- Preview before import
- Progress tracking
- Rollback on errors (transaction support)

**Benefits**:
- Bulk data loading
- Migration from other systems
- Seed data management

---

#### 7. Polymorphic Association Support
**Description**: Support for polymorphic relationships

**Features**:
- Detect polymorphic belongs_to relationships
- Type + ID field handling in forms
- Display polymorphic associations correctly
- Filter by polymorphic type

**Benefits**:
- Flexible data models (comments, attachments, etc.)
- Completes association support
- Common Rails pattern

**Complexity**: High - requires special UI handling

---

#### 8. Nested Forms for has_many
**Description**: Edit child records inline when editing parent

**Features**:
- Add/remove child records in parent form
- Inline editing of child attributes
- Nested validation handling
- Dynamic field addition with JavaScript
- Support for accepts_nested_attributes_for

**Benefits**:
- Edit related records without navigation
- Better UX for tightly coupled data
- Common pattern (e.g., invoice with line items)

**Complexity**: High - requires significant form logic

---

#### 9. Action Permissions/Authorization
**Description**: Integrate with authorization frameworks

**Features**:
- Conditional action visibility (hide Edit if not authorized)
- Integration with Pundit, CanCanCan, or similar
- Per-action authorization checks
- Graceful handling of unauthorized access
- Role-based action visibility

**Benefits**:
- Security enforcement
- Production-ready admin interfaces
- Multi-user/role support

---

#### 10. Audit Trail/Activity Log
**Description**: Track changes to records

**Features**:
- Automatic change logging
- "Who changed what and when" tracking
- Integration with PaperTrail or Audited gems
- View change history in UI
- Diff view for changes
- Restore previous versions

**Benefits**:
- Compliance and accountability
- Debugging data issues
- Undo functionality

---

#### 11. Custom Actions
**Description**: Add custom actions beyond CRUD

**Features**:
- Define custom member actions (e.g., "publish", "archive")
- Define custom collection actions (e.g., "import", "export")
- Automatic route generation
- Button rendering in UI
- Confirmation dialogs
- Custom action forms/modals

**Benefits**:
- Extend beyond basic CRUD
- Domain-specific operations
- Flexible admin interfaces

**Example**:
```ruby
class PostsController < ElaineCrud::BaseController
  model Post

  custom_action :publish,
    on: :member,
    method: :post,
    confirm: "Are you sure you want to publish this post?"

  def publish
    @record.update(published: true)
    redirect_to posts_path, notice: "Post published"
  end
end
```

---

#### 12. Dashboard/Stats Views
**Description**: Summary views with statistics and charts

**Features**:
- Configurable dashboard with widgets
- Count aggregations (total records, by status, etc.)
- Charts and graphs (using Chart.js or similar)
- Date range filtering
- Export stats

**Benefits**:
- Overview of data at a glance
- Business intelligence
- Common admin interface pattern

---

#### 13. Dark Mode Support
**Description**: Toggle between light and dark themes

**Features**:
- Dark mode CSS theme
- User preference persistence
- Toggle button in UI
- Respects system preferences
- All views compatible with dark mode

**Benefits**:
- Modern UI feature
- Accessibility and comfort
- User preference support

---

#### 14. Mobile Responsive Improvements
**Description**: Enhance mobile experience

**Features**:
- Card-based mobile layout (instead of table)
- Touch-friendly buttons and interactions
- Mobile-optimized forms
- Responsive navigation
- Swipe gestures

**Benefits**:
- Better mobile experience
- Accessibility
- Modern web standards

---

## 📝 Documentation Improvements

- [ ] Add comprehensive API documentation
- [ ] Create video tutorials
- [ ] Add more real-world examples
- [ ] Document testing strategies
- [ ] Create migration guide from other admin gems
- [ ] Add performance tuning guide
- [ ] Document accessibility features

---

## 🧪 Testing Improvements

- [ ] Increase test coverage to 95%+
- [ ] Add performance benchmarks
- [ ] Browser compatibility testing
- [ ] Accessibility testing (WCAG compliance)
- [ ] Load testing for large datasets
- [ ] Security testing

---

## 🔧 Technical Debt

- [ ] Refactor BaseHelper (getting large)
- [ ] Extract layout calculation to separate concern
- [ ] Improve error handling throughout
- [ ] Add deprecation warnings for future breaking changes
- [ ] Review and optimize database queries
- [ ] Add instrumentation/logging for debugging

---

## 💡 Ideas for Future Exploration

- GraphQL API support
- WebSocket support for real-time updates
- Multi-tenancy support
- Internationalization (i18n)
- API documentation generation (OpenAPI/Swagger)
- Form builder/designer UI
- Workflow/state machine support
- Scheduled actions (cron-like)
- Notification system integration
- File upload support with ActiveStorage
- Rich text editor integration (ActionText/Trix)
- Map/location field support
- Calendar/scheduling views

---

## Priority Matrix

**Do First** (High Impact, Low Effort):
1. Search/Filtering
2. Validation Error Display

**Schedule** (High Impact, High Effort):
3. Bulk Actions
4. Advanced Column Configuration

**Consider** (Low Impact, Low Effort):
5. Export Functionality
6. Dark Mode Support

**Defer** (Low Impact, High Effort):
7. Nested Forms
8. Audit Trail
9. Dashboard Views

---

## Contributing

Interested in implementing any of these features?

1. Pick a feature from the list
2. Create an issue to discuss the approach
3. Fork the repository
4. Implement the feature with tests
5. Update documentation
6. Submit a pull request

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for technical details.

---

## Questions?

- What features would be most valuable to your use case?
- What's missing from this list?
- What should be prioritized differently?

Open an issue to discuss!
