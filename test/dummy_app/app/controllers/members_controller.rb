# MembersController demonstrates dropdown options and date formatting
class MembersController < ElaineCrud::BaseController
  layout 'application'

  model Member
  permit_params :name, :email, :phone, :membership_type, :joined_at, :active

  default_sort column: :name, direction: :asc

  # Dropdown with predefined options
  field :membership_type do |f|
    f.title "Membership Type"
    f.options ["Standard", "Premium", "Student", "Senior"]
  end

  # Email with mailto link
  field :email do |f|
    f.display_as { |value, record|
      mail_to(value, value, class: "text-blue-600 hover:text-blue-800") if value.present?
    }
  end

  # Date formatting
  field :joined_at do |f|
    f.title "Member Since"
    f.display_as { |value, record|
      value&.strftime("%B %d, %Y")
    }
  end

  # Boolean active status
  field :active do |f|
    f.display_as { |value, record|
      value ? '✓ Active' : '✗ Inactive'
    }
  end

  # Foreign key: library_id auto-configured
  # has_many :loans auto-shown

  # Custom layout to give email and name fields more width
  def calculate_layout_header(fields)
    fields << "ROW-ACTIONS"

    fields.map do |field_name|
      width = case field_name.to_s
              when 'name' then "18%"
              when 'email' then "18%"
              when 'phone' then "13%"
              when 'membership_type' then "13%"
              when 'joined_at' then "12%"
              when 'active' then "8%"
              when 'library_id' then "10%"
              when 'ROW-ACTIONS' then "8%"
              else "10%"
              end

      {
        width: width,
        field_name: field_name
      }
    end
  end
end
