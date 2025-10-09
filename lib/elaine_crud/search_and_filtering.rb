# frozen_string_literal: true

module ElaineCrud
  # Methods for handling search and filtering of records
  # Provides global text search and per-field filtering capabilities
  module SearchAndFiltering
    extend ActiveSupport::Concern

    included do
      # Make search/filter methods available as helper methods in views
      helper_method :search_active?, :search_query, :filters if respond_to?(:helper_method)
    end

    # Apply search and filters to records
    # @param records [ActiveRecord::Relation] The base query
    # @return [ActiveRecord::Relation] Filtered query
    def apply_search_and_filters(records)
      records = apply_global_search(records) if search_query.present?
      records = apply_filters(records) if filters.present?
      records
    end

    # Get search query from params
    # @return [String, nil] The search term
    def search_query
      params[:search]
    end

    # Get filter parameters
    # @return [Hash] Filter parameters
    def filters
      filter_params = params[:filter] || {}
      # Convert ActionController::Parameters to Hash for compatibility
      filter_params.respond_to?(:to_unsafe_h) ? filter_params.to_unsafe_h : filter_params.to_h
    end

    # Apply global text search across searchable columns
    # @param records [ActiveRecord::Relation]
    # @return [ActiveRecord::Relation]
    def apply_global_search(records)
      # Get searchable columns (string/text types)
      searchable_columns = determine_searchable_columns

      return records if searchable_columns.empty?

      # Build OR conditions for each searchable column
      conditions = searchable_columns.map do |column|
        "LOWER(#{crud_model.table_name}.#{column}) LIKE :search"
      end

      records.where(conditions.join(' OR '), search: "%#{search_query.downcase}%")
    end

    # Apply individual field filters
    # @param records [ActiveRecord::Relation]
    # @return [ActiveRecord::Relation]
    def apply_filters(records)
      filters.each do |field, value|
        next if value.blank?

        # Skip special date range fields (handled separately)
        next if field.to_s.end_with?('_from', '_to')

        # Validate field is in the model
        next unless valid_filter_field?(field)

        records = apply_field_filter(records, field, value)
      end

      # Apply date range filters
      records = apply_date_range_filters(records)

      records
    end

    # Apply filter for a specific field
    # @param records [ActiveRecord::Relation]
    # @param field [String, Symbol] Field name
    # @param value [String, Array] Filter value
    # @return [ActiveRecord::Relation]
    def apply_field_filter(records, field, value)
      column_type = get_column_type(field)

      case column_type
      when :string, :text
        # Partial match for text fields
        records.where("LOWER(#{crud_model.table_name}.#{field}) LIKE ?", "%#{value.downcase}%")
      when :boolean
        # Exact match for booleans
        records.where(field => ActiveModel::Type::Boolean.new.cast(value))
      when :integer
        # Handle foreign keys and integers
        if value.is_a?(Array)
          records.where(field => value)
        else
          records.where(field => value)
        end
      else
        # Default: exact match
        records.where(field => value)
      end
    end

    # Apply date range filters
    # @param records [ActiveRecord::Relation]
    # @return [ActiveRecord::Relation]
    def apply_date_range_filters(records)
      date_fields = determine_date_columns

      date_fields.each do |field|
        from_key = "#{field}_from"
        to_key = "#{field}_to"

        if filters[from_key].present?
          records = records.where("#{crud_model.table_name}.#{field} >= ?", filters[from_key])
        end

        if filters[to_key].present?
          records = records.where("#{crud_model.table_name}.#{field} <= ?", filters[to_key])
        end
      end

      records
    end

    # Determine which columns are searchable (string/text types)
    # @return [Array<String>] Column names
    def determine_searchable_columns
      return [] unless crud_model

      searchable = []

      crud_model.columns.each do |col|
        # Include string/text columns that are displayed
        if [:string, :text].include?(col.type) &&
           !%w[id created_at updated_at].include?(col.name) &&
           determine_columns.include?(col.name)

          # Check if field is configured as searchable
          config = field_config_for(col.name.to_sym)
          if config&.respond_to?(:searchable)
            searchable << col.name if config.searchable
          else
            # Default: string/text fields are searchable
            searchable << col.name
          end
        end
      end

      searchable
    end

    # Determine which columns are filterable
    # @return [Array<Hash>] Array of hashes with field info
    def determine_filterable_columns
      return [] unless crud_model

      filterable = []

      determine_columns.each do |col_name|
        next if %w[id created_at updated_at].include?(col_name.to_s)

        config = field_config_for(col_name.to_sym)

        # Check if explicitly configured as filterable
        if config&.respond_to?(:filterable) && config.filterable
          filterable << {
            name: col_name.to_sym,
            type: infer_filter_type(col_name),
            config: config
          }
        end
      end

      filterable
    end

    # Get column type for a field
    # @param field [String, Symbol] Field name
    # @return [Symbol] Column type
    def get_column_type(field)
      column = crud_model.columns.find { |col| col.name == field.to_s }
      column&.type || :string
    end

    # Determine date columns for range filtering
    # @return [Array<String>] Column names
    def determine_date_columns
      return [] unless crud_model

      date_cols = []

      crud_model.columns.each do |col|
        if [:date, :datetime, :timestamp].include?(col.type) &&
           determine_columns.include?(col.name)

          # Check if this field is configured as filterable
          config = field_config_for(col.name.to_sym)
          if config&.respond_to?(:filterable) && config.filterable
            date_cols << col.name
          end
        end
      end

      date_cols
    end

    # Infer filter type from column type and configuration
    # @param field_name [String, Symbol] Field name
    # @return [Symbol] Filter type
    def infer_filter_type(field_name)
      column = crud_model.columns.find { |col| col.name == field_name.to_s }
      return :text unless column

      config = field_config_for(field_name.to_sym)

      # Use configured filter type if available
      return config.filter_type if config&.respond_to?(:filter_type) && config.filter_type

      # Infer from column type
      case column.type
      when :boolean then :boolean
      when :date, :datetime, :timestamp then :date_range
      when :integer
        # Check if it's a foreign key
        if field_name.to_s.end_with?('_id')
          :select
        else
          :text
        end
      else
        :text
      end
    end

    # Check if any search or filters are active
    # @return [Boolean]
    def search_active?
      search_query.present? || filters.present?
    end

    # Get total count without filters (for "X of Y results" display)
    # @return [Integer]
    def total_unfiltered_count
      @total_unfiltered_count ||= begin
        # Build base query without search/filters
        records = crud_model.all
        records = apply_has_many_filtering(records)
        records.count
      end
    end

    # Validate that a field is safe to filter on
    # @param field [String, Symbol] Field name
    # @return [Boolean]
    def valid_filter_field?(field)
      crud_model.column_names.include?(field.to_s)
    end
  end
end
