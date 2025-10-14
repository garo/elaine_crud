# LoansController demonstrates status badges, parent filtering, and date ranges
class LoansController < ElaineCrud::BaseController
  layout 'application'

  model Loan
  permit_params :book_copy_id, :member_id, :due_date, :returned_at, :status

  default_sort column: :due_date, direction: :desc

  # Virtual field: Book Title
  # This demonstrates a virtual field that doesn't exist on the Loan model
  # It accesses the associated book through book_copy
  field :book_title do |f|
    f.title "Book"
    f.readonly true
    f.visible true
    f.display_as lambda { |value, record|
      if record.book_copy && record.book_copy.book
        title = record.book_copy.book.title
        # Truncate long titles for display
        title.length > 50 ? "#{title[0..47]}..." : title
      else
        "—"
      end
    }
  end

  # Configure book_copy_id dropdown to show book titles
  field :book_copy_id do |f|
    f.title "Book Copy"

    # View mode: show only RFID
    f.display_as lambda { |value, record|
      if record.book_copy
        record.book_copy.rfid
      else
        "—"
      end
    }

    # Edit mode: show RFID + book title in dropdown
    f.foreign_key(
      model: BookCopy,
      display: lambda { |book_copy|
        if book_copy.book
          title = book_copy.book.title
          # Truncate to 60 characters for dropdown
          truncated_title = title.length > 60 ? "#{title[0..57]}..." : title
          "#{book_copy.rfid} - #{truncated_title}"
        else
          "#{book_copy.rfid} (Book Copy ##{book_copy.id})"
        end
      },
      scope: -> { BookCopy.includes(:book).order('books.title') }
    )
  end

  # Configure member_id dropdown
  field :member_id do |f|
    f.title "Member"
    f.foreign_key(
      model: Member,
      display: :name,
      scope: -> { Member.order(:name) }
    )
  end

  # Status with colored badges
  field :status do |f|
    f.title "Status"
    f.display_as lambda { |value, record|
      colors = {
        'pending' => 'gray',
        'active' => 'blue',
        'returned' => 'green',
        'overdue' => 'red'
      }
      color = colors[value] || 'gray'
      content_tag(:span, value.titleize,
        class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-#{color}-100 text-#{color}-800")
    }
    f.options ["pending", "active", "returned", "overdue"]
  end

  # Due date with overdue highlighting
  field :due_date do |f|
    f.title "Due Date"
    f.display_as { |value, record|
      formatted = value&.strftime("%m/%d/%Y")
      if record.status == 'overdue'
        content_tag(:span, formatted, class: 'text-red-600 font-semibold')
      else
        formatted
      end
    }
  end

  # Returned date
  field :returned_at do |f|
    f.title "Returned"
    f.visible true  # Override default hiding of _at fields
    f.display_as { |value, record|
      value ? time_ago_in_words(value) + " ago" : "—"
    }
  end

  # Foreign keys: book_copy_id, member_id auto-configured
  # Parent filtering works: /loans?member_id=1 shows loans for that member
  # Can also filter by book_copy: /loans?book_copy_id=1
end
