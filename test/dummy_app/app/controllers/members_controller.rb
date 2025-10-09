# MembersController demonstrates dropdown options and date formatting
class MembersController < ElaineCrud::BaseController
  layout 'application'

  model Member
  permit_params :name, :email, :phone, :membership_type, :joined_at, :active

  default_sort column: :name, direction: :asc

  # Name field - searchable
  field :name do |f|
    f.searchable true
  end

  # Email - searchable with mailto link
  field :email do |f|
    f.searchable true
    f.display_as { |value, record|
      mail_to(value, value, class: "text-blue-600 hover:text-blue-800") if value.present?
    }
  end

  # Dropdown with predefined options - filterable
  field :membership_type do |f|
    f.title "Membership Type"
    f.options ["Standard", "Premium", "Student", "Senior"]
    f.filterable true
    f.filter_type :select
  end

  # Date formatting - filterable with date range
  field :joined_at do |f|
    f.title "Member Since"
    f.display_as { |value, record|
      value&.strftime("%B %d, %Y")
    }
    f.filterable true
    f.filter_type :date_range
  end

  # Boolean active status - filterable
  field :active do |f|
    f.display_as { |value, record|
      value ? '✓ Active' : '✗ Inactive'
    }
    f.filterable true
    f.filter_type :boolean
  end

  # Library foreign key - filterable
  field :library_id do |f|
    f.filterable true
    f.filter_type :select
  end

  # Foreign key: library_id auto-configured
  # has_many :loans auto-shown

  # Example on how to customize the column widths
  def calculate_layout_header(fields)
    fields << "ROW-ACTIONS"

    fields.map do |field_name|
      # Using minmax() allows columns to expand when content is too large
      width = case field_name.to_s
              when 'name' then "minmax(140px, 1.8fr)"
              when 'email' then "minmax(140px, 1.8fr)"
              when 'phone' then "minmax(110px, 1.3fr)"
              when 'membership_type' then "minmax(120px, 1.3fr)"
              when 'joined_at' then "minmax(110px, 1.2fr)"
              when 'active' then "minmax(80px, 0.8fr)"
              when 'library_id' then "minmax(100px, 1fr)"
              when 'ROW-ACTIONS' then "minmax(90px, 0.8fr)"
              else "minmax(100px, 1fr)"
              end

      {
        width: width,
        field_name: field_name
      }
    end
  end
end
