# frozen_string_literal: true

class TagsController < ElaineCrud::BaseController
  layout 'application'

  model Tag
  permit_params :name, :color  # book_ids will be auto-added by refresh_permitted_attributes

  default_sort column: :name, direction: :asc

  field :name do |f|
    f.searchable true
  end

  field :color do |f|
    f.title "Color"
    f.description "Hex color code (e.g., #3B82F6)"
    f.display_as { |value, record|
      content_tag(:span, value,
        class: "inline-block px-3 py-1 rounded text-white font-medium",
        style: "background-color: #{value}"
      )
    }
  end

  # Books HABTM relationship uses default minimal display
  # Shows: "Book 1, Book 2, Book 3, ..."
end
