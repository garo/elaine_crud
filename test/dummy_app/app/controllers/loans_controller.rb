# LoansController demonstrates status badges, parent filtering, and date ranges
class LoansController < ElaineCrud::BaseController
  layout 'application'

  model Loan
  permit_params :due_date, :returned_at, :status

  default_sort column: :due_date, direction: :desc

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

  # Foreign keys: book_id, member_id auto-configured
  # Parent filtering works: /loans?member_id=1 shows loans for that member
end
