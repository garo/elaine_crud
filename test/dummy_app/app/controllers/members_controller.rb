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
end
