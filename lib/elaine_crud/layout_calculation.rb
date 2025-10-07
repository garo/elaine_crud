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
    #   - width: CSS width (required, e.g., "minmax(100px, 1fr)" or "25%")
    #   - field_name: Symbol of field to display and enable sorting (optional)
    #   - title: Custom column title, overrides field title (optional)
    def calculate_layout_header(fields)
      # Default implementation: flexible columns that can expand to fit content
      # Using minmax() allows columns to grow beyond their base size when content requires it
      fields << "ROW-ACTIONS"

      fields.map do |field_name|
        {
          width: "minmax(100px, 1fr)",
          field_name: field_name
        }
      end
    end
  end
end
