# AuthorsController demonstrates boolean fields and has_many relationships
class AuthorsController < ElaineCrud::BaseController
  layout 'application'

  model Author
  permit_params :name, :biography, :birth_year, :country, :active

  default_sort column: :name, direction: :asc
  show_view_button

  # Custom display for active status
  field :active do |f|
    f.title "Status"
    f.display_as { |value, record|
      if value
        content_tag(:span, '✓ Active', class: 'text-green-600 font-semibold')
      else
        content_tag(:span, '✗ Inactive', class: 'text-gray-600')
      end
    }
  end

  # has_many :books automatically displayed with count
end
