# frozen_string_literal: true

module ElaineCrud
  # Concern for sorting functionality in ElaineCrud controllers
  # Provides methods for URL parameter-based sorting with validation
  module SortingConcern
    extend ActiveSupport::Concern

    # Get current sort column from params or default
    # @return [Symbol] The sort column
    def current_sort_column
      if params[:sort].present? && valid_sort_column?(params[:sort])
        params[:sort].to_sym
      else
        self.class.default_sort_column || :id
      end
    end

    # Get current sort direction from params or default
    # @return [Symbol] The sort direction (:asc or :desc)
    def current_sort_direction
      if params[:direction].present? && %w[asc desc].include?(params[:direction])
        params[:direction].to_sym
      else
        self.class.default_sort_direction || :asc
      end
    end

    # Get the opposite direction for toggling sort
    # @param current_direction [Symbol] Current sort direction
    # @return [Symbol] Opposite direction
    def toggle_sort_direction(current_direction)
      current_direction.to_sym == :asc ? :desc : :asc
    end

    private

    # Apply sorting to the records based on URL parameters
    # @param records [ActiveRecord::Relation] The base query
    # @return [ActiveRecord::Relation] The sorted query
    def apply_sorting(records)
      sort_column = current_sort_column
      sort_direction = current_sort_direction

      # Validate sort column exists
      return records unless valid_sort_column?(sort_column)

      # Use Arel to safely construct ORDER BY clause
      # This prevents SQL injection in column names
      table = crud_model.arel_table
      records.order(table[sort_column].send(sort_direction))
    end

    # Check if a column is valid for sorting
    # @param column [String, Symbol] The column name
    # @return [Boolean] True if valid for sorting
    def valid_sort_column?(column)
      return false if column.blank?

      column_str = column.to_s
      crud_model.column_names.include?(column_str) || 
      crud_model.attribute_names.include?(column_str)
    end
  end
end