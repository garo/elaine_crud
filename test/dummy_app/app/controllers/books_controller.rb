# BooksController demonstrates foreign keys, currency, and custom display
class BooksController < ElaineCrud::BaseController
  layout 'application'

  model Book
  permit_params :title, :isbn, :publication_year, :pages, :description, :available, :price

  default_sort column: :title, direction: :asc

  # Currency field
  field :price do |f|
    f.title "Price"
    f.display_as { |value, record|
      number_to_currency(value) if value.present?
    }
  end

  # Boolean with custom display
  field :available do |f|
    f.title "Availability"
    f.display_as { |value, record|
      if value
        content_tag(:span, '✓ Available', class: 'inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-green-100 text-green-800')
      else
        content_tag(:span, '✗ Checked Out', class: 'inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-red-100 text-red-800')
      end
    }
  end

  # Foreign keys auto-detected: author_id, library_id
  # Automatically shows dropdowns in forms and names in index

  # has_many :loans automatically shown with count
end
