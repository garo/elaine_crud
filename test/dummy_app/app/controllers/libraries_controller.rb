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
      # Using minmax() allows columns to expand when content is too large
      width = case field_name.to_s
              when 'name' then "minmax(150px, 2fr)"
              when 'email' then "minmax(150px, 1.8fr)"
              when 'city' then "minmax(100px, 1.2fr)"
              when 'state' then "minmax(60px, 0.8fr)"
              when 'phone' then "minmax(120px, 1.4fr)"
              when 'established_date' then "minmax(120px, 1.4fr)"
              when 'ROW-ACTIONS' then "minmax(120px, 1.4fr)"
              else "minmax(100px, 1fr)"
              end

      {
        width: width,
        field_name: field_name
      }
    end
  end
end
