# LibrariesController demonstrates basic CRUD with has_many relationships
class LibrariesController < ElaineCrud::BaseController
  layout 'application'

  model Library
  permit_params :name, :city, :state, :phone, :email, :established_date

  # Default sorting by name
  default_sort column: :name, direction: :asc

  # Customize email field display
  field :email do |f|
    f.title "Email Address"
    f.display_as { |value, record|
      mail_to(value) if value.present?
    }
  end

  # Format established date
  field :established_date do |f|
    f.title "Established"
    f.display_as { |value, record|
      value&.strftime("%B %Y")
    }
  end

  # has_many relationships auto-detected and displayed
  # Shows: books, members, librarians with counts

  # Custom layout to give email field more width
  def calculate_layout_header(fields)
    fields << "ROW-ACTIONS"

    fields.map do |field_name|
      # Give email and name fields more width
      width = case field_name.to_s
              when 'name' then "20%"
              when 'email' then "18%"
              when 'city' then "12%"
              when 'state' then "8%"
              when 'phone' then "14%"
              when 'established_date' then "14%"
              when 'ROW-ACTIONS' then "14%"
              else "10%"
              end

      {
        width: width,
        field_name: field_name
      }
    end
  end
end
