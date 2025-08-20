# ElaineCrud DSL Examples

This document shows comprehensive examples of the ElaineCrud field DSL framework that has been implemented. All examples include TODO comments since the actual functionality is not yet implemented.

## Basic Field Configuration

```ruby
class PeopleController < ElaineCrud::BaseController
  model Person
  permit_params :name, :email, :role, :active, :company_id, :salary
  
  # Simple hash-style configuration
  field :name, title: "Full Name", description: "Enter first and last name"
  
  # Block-style configuration for complex setups
  field :email do |f|
    f.title "Email Address"
    f.description "Primary contact email"
    f.display_as { |value| mail_to(value) if value.present? }
    f.edit_as { |value| email_field_tag(field_name, value, class: "form-input") }
  end
end
```

## Dropdown Options

```ruby
class ProductController < ElaineCrud::BaseController
  model Product
  permit_params :name, :status, :category
  
  # Array of options
  field :status, 
    title: "Product Status",
    options: ["draft", "published", "archived"]
  
  # Hash mapping display => value
  field :category,
    title: "Product Category", 
    options: {
      "Consumer Electronics" => "electronics",
      "Home & Garden" => "home_garden", 
      "Books & Media" => "books"
    }
end
```

## Foreign Key Relationships

```ruby
class EmployeeController < ElaineCrud::BaseController
  model Employee
  permit_params :name, :email, :company_id, :department_id
  
  # Basic foreign key - displays with to_s
  field :company_id do |f|
    f.title "Company"
    f.description "Select the company this employee works for"
    f.foreign_key model: Company
  end
  
  # Foreign key with custom display and scoping
  field :department_id do |f|
    f.title "Department"
    f.foreign_key model: Department,
                  display: ->(dept) { "#{dept.name} (#{dept.location})" },
                  scope: -> { Department.active.order(:name) },
                  null_option: "Select a department..."
  end
end
```

## Custom Display and Edit Callbacks

```ruby
class TransactionController < ElaineCrud::BaseController
  model Transaction
  permit_params :amount, :description, :transaction_type, :processed_at
  
  # Method reference for display callback
  field :amount,
    title: "Transaction Amount",
    display_as: :format_currency,
    edit_as: :currency_input
  
  # Inline block for display
  field :transaction_type do |f|
    f.title "Type"
    f.display_as { |value| 
      case value
      when 'credit' then content_tag(:span, 'Credit', class: 'text-green-600 font-semibold')
      when 'debit' then content_tag(:span, 'Debit', class: 'text-red-600 font-semibold')
      else value.to_s.titleize
      end
    }
    f.options ["credit", "debit", "transfer"]
  end
  
  private
  
  def format_currency(value, record)
    number_to_currency(value) if value
  end
  
  def currency_input(value, record, form)
    form.number_field(:amount, step: 0.01, class: "form-input", placeholder: "0.00")
  end
end
```

## Read-Only Fields with Defaults

```ruby
class OrderController < ElaineCrud::BaseController
  model Order
  permit_params :customer_name, :total_amount, :status, :order_number, :created_by
  
  # Read-only with static default
  field :order_number,
    title: "Order Number",
    description: "Automatically generated unique identifier",
    readonly: true,
    default_value: -> { "ORD-#{SecureRandom.alphanumeric(8).upcase}" }
  
  # Read-only timestamp with custom formatting
  field :created_at,
    title: "Order Date",
    readonly: true,
    display_as: :format_order_date
  
  # Read-only field populated from session/context
  field :created_by,
    title: "Created By",
    readonly: true,
    default_value: -> { current_user&.name }
    
  private
  
  def format_order_date(value, record)
    value&.strftime("%B %d, %Y at %I:%M %p")
  end
  
  def current_user
    # In this app, user info comes from reverse proxy headers
    OpenStruct.new(name: request.headers['X-Forwarded-User'])
  end
end
```

## Complex Real-World Example

```ruby
class UserController < ElaineCrud::BaseController
  model User
  permit_params :name, :email, :role, :company_id, :department_id, :salary, :active, :hire_date
  
  # Basic text field with validation
  field :name do |f|
    f.title "Full Name"
    f.description "Enter the employee's first and last name"
    f.display_as { |value| content_tag(:strong, value) }
  end
  
  # Email with custom display and validation
  field :email do |f|
    f.title "Email Address"
    f.description "Primary work email address"
    f.display_as { |value| mail_to(value, value, class: "text-blue-600") }
    f.edit_as { |value, record, form| 
      form.email_field(:email, value: value, required: true, class: "form-input")
    }
  end
  
  # Dropdown with predefined options
  field :role,
    title: "Job Role",
    description: "Employee's primary role in the organization",
    options: ["Developer", "Designer", "Manager", "Admin", "HR"]
  
  # Foreign key to Company with custom display
  field :company_id do |f|
    f.title "Company"
    f.description "Select the company this employee works for"
    f.foreign_key model: Company,
                  display: ->(company) { "#{company.name} (#{company.city})" },
                  scope: -> { Company.active.includes(:address) },
                  null_option: "Select a company..."
  end
  
  # Foreign key to Department filtered by company
  field :department_id do |f|
    f.title "Department"
    f.description "Select the department within the company"
    f.foreign_key model: Department,
                  display: :name_with_code,
                  scope: -> { Department.joins(:company).where(company: company_scope) }
  end
  
  # Currency field with formatting
  field :salary do |f|
    f.title "Annual Salary"
    f.description "Base annual salary in USD"
    f.display_as :format_salary
    f.edit_as { |value, record, form|
      form.number_field(:salary, value: value, step: 1000, min: 0, 
                       class: "form-input", placeholder: "Enter amount")
    }
  end
  
  # Boolean with custom display
  field :active,
    title: "Active Employee",
    description: "Is this person currently employed?",
    display_as: ->(value) { 
      if value
        content_tag(:span, "✅ Active", class: "text-green-600 font-semibold")
      else
        content_tag(:span, "❌ Inactive", class: "text-red-600 font-semibold")
      end
    }
  
  # Date field with custom formatting
  field :hire_date do |f|
    f.title "Hire Date"
    f.description "Employee's first day of work"
    f.display_as { |value| value&.strftime("%B %d, %Y") }
    f.default_value -> { Date.current }
  end
  
  private
  
  def format_salary(value, record)
    return "Not disclosed" if value.blank?
    number_to_currency(value, precision: 0)
  end
  
  def company_scope
    # This would be used to filter departments by selected company
    # Implementation would need to be dynamic based on form state
    Company.all
  end
end
```

## Field Configuration Reference

### Available Options

| Option | Type | Description | Example |
|--------|------|-------------|---------|
| `title` | String | Human-readable field title | `"Full Name"` |
| `description` | String | Help text for forms | `"Enter first and last name"` |
| `readonly` | Boolean | Prevents editing | `true` |
| `default_value` | Value/Proc | Default for new records | `-> { Date.current }` |
| `display_as` | Symbol/Proc | Custom display rendering | `:format_currency` |
| `edit_as` | Symbol/Proc | Custom form field rendering | `{ |v| email_field(...) }` |
| `options` | Array/Hash | Dropdown options | `["option1", "option2"]` |
| `foreign_key` | Hash | Foreign key configuration | `{ model: Company, display: :name }` |

### Foreign Key Configuration

```ruby
field :company_id do |f|
  f.foreign_key model: Company,                    # Required: target model
                display: :name,                    # Optional: how to display (Symbol/Proc)
                scope: -> { Company.active },      # Optional: filter records
                null_option: "Select company..."   # Optional: placeholder text
end
```

### Callback Signatures

```ruby
# Display callbacks
display_as: :method_name          # Calls controller.method_name(value, record)
display_as: { |value, record| ... } # Inline block

# Edit callbacks  
edit_as: :method_name             # Calls controller.method_name(value, record, form)
edit_as: { |value, record, form| ... } # Inline block

# Default value callbacks
default_value: -> { Time.current } # Called in controller context
```

All of these examples are currently placeholders with TODO comments in the actual implementation. Each feature needs to be implemented one by one in the FieldConfiguration and BaseController classes.