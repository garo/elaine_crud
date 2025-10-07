# frozen_string_literal: true

module ElaineCrud
  # Methods for fetching records and determining column visibility
  # Handles data retrieval, scoping, and column selection
  module RecordFetching
    extend ActiveSupport::Concern

    private

    # Fetch all records for index view
    # Can be overridden in subclasses for custom filtering/scoping
    # @return [ActiveRecord::Relation] The records to display
    def fetch_records
      records = crud_model.all

      # Apply parent filtering for has_many relationships
      records = apply_has_many_filtering(records)

      # Include all relationships to avoid N+1 queries
      includes_list = get_all_relationship_includes
      records = records.includes(includes_list) if includes_list.any?

      apply_sorting(records)
    end

    # Find a single record by ID
    # @return [ActiveRecord::Base] The found record
    def find_record
      crud_model.find(params[:id])
    end

    # Find a record by a specific ID (used for inline editing)
    # @param id [Integer] The record ID
    # @return [ActiveRecord::Base, nil] The found record or nil
    def find_record_by_id(id)
      crud_model.find(id)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    # Determine which columns to display
    # @return [Array<String>] List of column names to display
    def determine_columns
      # Get all potential columns (database columns + configured virtual fields)
      db_columns = crud_model.column_names
      virtual_fields = configured_virtual_fields
      all_columns = (db_columns + virtual_fields).uniq

      # Filter columns based on field configurations and new visibility rules
      all_columns.select do |col|
        field_config = field_config_for(col.to_sym)

        if field_config&.visible == false
          # Explicitly hidden via field configuration
          false
        elsif field_config&.visible == true
          # Explicitly shown via field configuration (even if it ends with '_at')
          true
        elsif virtual_fields.include?(col)
          # Virtual fields are shown if configured (like has_many relationships)
          true
        else
          # Default behavior for DB columns: hide columns ending with '_at', show everything else
          !col.end_with?('_at')
        end
      end
    end

    # Get list of configured virtual fields (non-database columns)
    # @return [Array<String>] List of configured virtual field names
    def configured_virtual_fields
      return [] unless field_configurations

      virtual_fields = []
      field_configurations.each do |field_name, config|
        field_name_str = field_name.to_s

        # Include if it's not a database column but is configured
        unless crud_model.column_names.include?(field_name_str)
          virtual_fields << field_name_str
        end
      end

      virtual_fields
    end
  end
end
