# BooksController demonstrates foreign keys, currency, and custom display
class BooksController < ElaineCrud::BaseController
  layout 'application'

  model Book
  permit_params :author_id, :title, :isbn, :publication_year, :pages, :description, :available, :price, :ebook_url

  default_sort column: :title, direction: :asc
  show_view_button

  # Currency field
  field :price do |f|
    f.title "Price"
    f.display_as { |value, record|
      number_to_currency(value) if value.present?
    }
  end

  # eBook URL - display as clickable link
  field :ebook_url do |f|
    f.title "eBook"
    f.display_as { |value, record|
      if value.present?
        link_to "View eBook", value,
          target: "_blank",
          rel: "noopener noreferrer",
          class: "text-blue-600 hover:text-blue-800 underline"
      else
        content_tag(:span, "—", class: "text-gray-400")
      end
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

  # Foreign key with nested create support
  field :author_id do |f|
    f.foreign_key(
      model: Author,
      display: :name
    )
    f.nested_create true  # Enable creating new authors from book form
  end

  # has_many :book_copies automatically shown with count
  # has_many :loans through :book_copies

  # has_and_belongs_to_many :tags - custom polished display
  # This showcases how developers can build on ElaineCrud's minimal HABTM infrastructure
  # to create domain-specific, visually polished UI
  field :tags do |f|
    f.title "Tags"
    f.description "Book tags and categories"
    f.display_as { |value, record|
      tags = record.tags

      # Handle empty case with styled placeholder
      if tags.empty?
        next content_tag(:span, "No tags", class: "text-gray-400 italic text-sm")
      end

      # Render each tag as a colored badge using the tag's color field
      max_display = 5
      displayed_tags = tags.first(max_display)

      tags_html = displayed_tags.map { |tag|
        content_tag(:span, tag.name,
          class: "inline-block px-2 py-1 text-xs font-semibold rounded-full text-white mr-1 mb-1",
          style: "background-color: #{tag.color}"
        )
      }.join.html_safe

      # Show "+N more" indicator if there are additional tags
      if tags.count > max_display
        tags_html + content_tag(:span, "+#{tags.count - max_display} more",
          class: "text-xs text-gray-500 ml-1")
      else
        tags_html
      end
    }
  end

  # Custom two-row layout for better content display
  def calculate_layout(content, fields)
    # Row 1: All regular fields displayed normally (each takes 1 column)
    # Row 2: Description spans most columns, with tags and book_copies info

    row1 = [
      { field_name: :title, colspan: 1, rowspan: 1 },
      { field_name: :isbn, colspan: 1, rowspan: 1 },
      { field_name: :author_id, colspan: 1, rowspan: 1 },
      { field_name: :publication_year, colspan: 1, rowspan: 1 },
      { field_name: :pages, colspan: 1, rowspan: 1 },
      { field_name: :price, colspan: 1, rowspan: 1 },
      { field_name: :available, colspan: 1, rowspan: 1 },
      { field_name: :ebook_url, colspan: 1, rowspan: 1 }
    ]

    row2 = [
      { field_name: :description, colspan: 3, rowspan: 1 },
      { field_name: :tags, colspan: 3, rowspan: 1 },
      { field_name: :book_copies, colspan: 2, rowspan: 1 }
    ]

    [row1, row2]
  end

  # Custom header layout - defines the grid column structure
  # Header only shows fields from row 1, as row 2 fields span across those columns
  def calculate_layout_header(fields)
    # Only include fields that appear in row 1 (the actual column structure)
    header_fields = [:title, :isbn, :author_id, :publication_year, :pages, :price, :available, :ebook_url]
    header_fields << "ROW-ACTIONS"

    header_fields.map do |field_name|
      # Using minmax() allows columns to expand when content is too large
      width = case field_name.to_s
              when 'title' then "minmax(120px, 1.5fr)"
              when 'isbn' then "minmax(90px, 1fr)"
              when 'author_id' then "minmax(100px, 1.2fr)"
              when 'publication_year' then "minmax(70px, 0.8fr)"
              when 'pages' then "minmax(60px, 0.6fr)"
              when 'price' then "minmax(70px, 0.7fr)"
              when 'available' then "minmax(100px, 1.1fr)"
              when 'ebook_url' then "minmax(90px, 0.9fr)"
              when 'ROW-ACTIONS' then "minmax(100px, 1.2fr)"
              else "minmax(100px, 1fr)"
              end

      { width: width, field_name: field_name }
    end
  end
end
