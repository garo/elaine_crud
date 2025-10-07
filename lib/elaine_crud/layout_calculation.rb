# frozen_string_literal: true

module ElaineCrud
  # Methods for calculating and customizing layout and grid structure
  # Handles column widths, row layouts, and field positioning
  module LayoutCalculation
    extend ActiveSupport::Concern

    # Calculate layout structure for a specific record
    # @param content [ActiveRecord::Base] The record being displayed
    # @param fields [Array<Symbol>] Array of field names to include in layout
    # @return [Array<Array<Hash>>] Nested array where first dimension is rows, second is columns
    #   Each column hash can contain: field_name, colspan, rowspan, and future properties
    def calculate_layout(content, fields)
      # Default implementation: single row with all fields, each taking 1 column and 1 row
      row = fields.map do |field_name|
        {
          field_name: field_name,
          colspan: 1,
          rowspan: 1
        }
      end

      [row] # Return single row
    end

    # Calculate layout header structure defining column sizes and titles
    # @param fields [Array<Symbol>] Array of field names to include in layout
    # @return [Array<Hash>] Array of header config objects with width, field_name, and/or title
    #   Each object can contain:
    #   - width: CSS width (required, e.g., "25%")
    #   - field_name: Symbol of field to display and enable sorting (optional)
    #   - title: Custom column title, overrides field title (optional)
    def calculate_layout_header(fields)
      # Default implementation: equal distribution with field names for sorting
      fields << "ROW-ACTIONS"
      field_count = fields.length
      percentage = (100.0 / field_count).round(1)

      fields.map do |field_name|
        {
          width: "#{percentage}%",
          field_name: field_name
        }
      end
    end
  end
end
