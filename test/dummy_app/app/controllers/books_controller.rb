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

  # Custom two-row layout for better content display
  def calculate_layout(content, fields)
    # Row 1: All regular fields displayed normally (each takes 1 column)
    # Row 2: Description spans most columns, with loans info at the end

    row1 = [
      { field_name: :title, colspan: 1, rowspan: 1 },
      { field_name: :isbn, colspan: 1, rowspan: 1 },
      { field_name: :author_id, colspan: 1, rowspan: 1 },
      { field_name: :library_id, colspan: 1, rowspan: 1 },
      { field_name: :publication_year, colspan: 1, rowspan: 1 },
      { field_name: :pages, colspan: 1, rowspan: 1 },
      { field_name: :price, colspan: 1, rowspan: 1 },
      { field_name: :available, colspan: 1, rowspan: 1 }
    ]

    row2 = [
      { field_name: :description, colspan: 6, rowspan: 1 },
      { field_name: :loans, colspan: 2, rowspan: 1 }
    ]

    [row1, row2]
  end

  # Custom header layout - defines the grid column structure
  # Header only shows fields from row 1, as row 2 fields span across those columns
  def calculate_layout_header(fields)
    # Only include fields that appear in row 1 (the actual column structure)
    header_fields = [:title, :isbn, :author_id, :library_id, :publication_year, :pages, :price, :available]
    header_fields << "ROW-ACTIONS"

    header_fields.map do |field_name|
      # Using minmax() allows columns to expand when content is too large
      width = case field_name.to_s
              when 'title' then "minmax(120px, 1.4fr)"
              when 'isbn' then "minmax(90px, 1fr)"
              when 'author_id' then "minmax(100px, 1.1fr)"
              when 'library_id' then "minmax(100px, 1.1fr)"
              when 'publication_year' then "minmax(70px, 0.8fr)"
              when 'pages' then "minmax(60px, 0.6fr)"
              when 'price' then "minmax(70px, 0.7fr)"
              when 'available' then "minmax(100px, 1.1fr)"
              when 'ROW-ACTIONS' then "minmax(100px, 1.2fr)"
              else "minmax(100px, 1fr)"
              end

      { width: width, field_name: field_name }
    end
  end
end
