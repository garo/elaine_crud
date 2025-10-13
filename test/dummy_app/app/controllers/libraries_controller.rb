# LibrariesController demonstrates basic CRUD with has_many relationships
class LibrariesController < ElaineCrud::BaseController
  layout 'application'

  model Library
  permit_params :name, :city, :state, :phone, :email, :established_date

  # Default sorting by name
  default_sort column: :name, direction: :asc
  show_view_button

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

  # Override show to add custom computed statistics and sub-table data
  def show
    # Set up base instance variables (same as ElaineCrud::BaseController#show)
    @record = find_record
    @model_name = crud_model.name
    @columns = determine_columns

    # Computed statistics for the instruction text
    @total_book_copies = @record.book_copies.count
    @unique_books = @record.books.distinct.count
    @available_copies = @record.book_copies.where(available: true).count
    @active_members = @record.members.where(active: true).count

    # Data for librarians sub-table
    @librarians = @record.librarians.order(:name)
    @librarian_columns = [:name, :email, :role, :salary]

    # Render custom view instead of default
    render 'libraries/show'
  end
end
