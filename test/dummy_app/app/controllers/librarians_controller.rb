# LibrariansController demonstrates readonly fields and role dropdowns
class LibrariansController < ElaineCrud::BaseController
  layout 'application'

  model Librarian
  permit_params :name, :email, :role, :hire_date, :salary

  default_sort column: :name, direction: :asc

  # Role dropdown
  field :role do |f|
    f.title "Role"
    f.options ["Manager", "Assistant", "Clerk", "Archivist"]
  end

  # Email with mailto
  field :email do |f|
    f.display_as { |value, record|
      mail_to(value) if value.present?
    }
  end

  # Currency field
  field :salary do |f|
    f.title "Annual Salary"
    f.display_as { |value, record|
      number_to_currency(value, precision: 0) if value.present?
    }
  end

  # Date formatting
  field :hire_date do |f|
    f.title "Hired On"
    f.display_as { |value, record|
      value&.strftime("%B %d, %Y")
    }
  end

  # Foreign key: library_id auto-configured

  # Custom layout to give email and name fields more width
  def calculate_layout_header(fields)
    fields << "ROW-ACTIONS"

    fields.map do |field_name|
      width = case field_name.to_s
              when 'name' then "18%"
              when 'email' then "20%"
              when 'role' then "12%"
              when 'hire_date' then "13%"
              when 'salary' then "12%"
              when 'library_id' then "15%"
              when 'ROW-ACTIONS' then "10%"
              else "10%"
              end

      {
        width: width,
        field_name: field_name
      }
    end
  end
end
