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


end
