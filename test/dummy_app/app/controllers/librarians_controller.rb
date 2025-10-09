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

end
