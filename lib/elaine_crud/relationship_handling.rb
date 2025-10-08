# frozen_string_literal: true

module ElaineCrud
  # Methods for handling ActiveRecord relationships (belongs_to, has_many)
  # Provides eager loading, filtering, and parent context management
  module RelationshipHandling
    extend ActiveSupport::Concern

    # Get list of belongs_to associations to include for avoiding N+1 queries
    # @return [Array<Symbol>] List of association names to include
    def get_belongs_to_includes
      return [] unless crud_model

      includes = []

      # Get all belongs_to relationships that are displayed
      crud_model.reflections.each do |name, reflection|
        next unless reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection)

        foreign_key = reflection.foreign_key.to_sym

        # Include if this foreign key is in the displayed columns or configured
        if determine_columns.include?(foreign_key.to_s) || field_configured?(foreign_key)
          includes << name.to_sym
        end
      end

      includes
    end

    # Get has_many relationships that need to be included
    # @return [Array<Symbol>] List of association names to include
    def get_has_many_includes
      return [] unless crud_model

      includes = []

      crud_model.reflections.each do |name, reflection|
        next unless reflection.is_a?(ActiveRecord::Reflection::HasManyReflection)

        # Include if this relationship is displayed in columns or configured
        if determine_columns.include?(name) || field_configured?(name.to_sym)
          includes << name.to_sym
        end
      end

      includes
    end

    # Get has_one relationships that need to be included
    # @return [Array<Symbol>] List of association names to include
    def get_has_one_includes
      return [] unless crud_model

      includes = []

      crud_model.reflections.each do |name, reflection|
        next unless reflection.is_a?(ActiveRecord::Reflection::HasOneReflection)

        # Include if this relationship is displayed in columns or configured
        if determine_columns.include?(name) || field_configured?(name.to_sym)
          includes << name.to_sym
        end
      end

      includes
    end

    # Get list of associations to include for avoiding N+1 queries
    # @return [Array<Symbol>] List of association names to include
    def get_all_relationship_includes
      return [] unless crud_model

      includes = []

      # Include belongs_to relationships (existing logic)
      includes += get_belongs_to_includes

      # Include has_many relationships that are displayed
      includes += get_has_many_includes

      # Include has_one relationships that are displayed
      includes += get_has_one_includes

      includes.uniq
    end

    # Apply filtering based on parent relationship parameters
    # @param records [ActiveRecord::Relation] The base query
    # @return [ActiveRecord::Relation] Filtered query
    def apply_has_many_filtering(records)
      parent_filters = detect_parent_filters

      parent_filters.each do |parent_field, parent_id|
        next unless parent_id.present?

        # Validate that this is a legitimate foreign key
        if valid_parent_filter?(parent_field)
          records = records.where(parent_field => parent_id)

          # Set instance variables for UI context
          set_parent_context(parent_field, parent_id)
        end
      end

      records
    end

    # Detect parent filter parameters from URL
    # @return [Hash] Hash of foreign_key => parent_id
    def detect_parent_filters
      parent_filters = {}

      # Look for foreign key parameters in the URL
      crud_model.reflections.each do |name, reflection|
        next unless reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection)

        foreign_key = reflection.foreign_key.to_sym
        param_value = params[foreign_key]

        if param_value.present?
          parent_filters[foreign_key] = param_value
        end
      end

      parent_filters
    end

    # Validate that the parent filter is legitimate
    # @param field_name [Symbol] The field name to validate
    # @return [Boolean] True if valid foreign key column
    def valid_parent_filter?(field_name)
      crud_model.column_names.include?(field_name.to_s) &&
      field_name.to_s.end_with?('_id')
    end

    # Set context for UI display
    # @param parent_field [Symbol] The foreign key field
    # @param parent_id [Integer] The parent record ID
    def set_parent_context(parent_field, parent_id)
      reflection = find_reflection_by_foreign_key(parent_field)
      return unless reflection

      begin
        parent_record = reflection.klass.find(parent_id)
        @parent_context = {
          record: parent_record,
          relationship_name: reflection.name,
          foreign_key: parent_field,
          model_class: reflection.klass
        }
      rescue ActiveRecord::RecordNotFound
        @parent_context = {
          error: "#{reflection.klass.name} with ID #{parent_id} not found",
          foreign_key: parent_field,
          model_class: reflection.klass
        }
      end
    end

    # Find reflection by foreign key name
    # @param foreign_key [Symbol] The foreign key field
    # @return [ActiveRecord::Reflection::BelongsToReflection, nil] The reflection or nil
    def find_reflection_by_foreign_key(foreign_key)
      crud_model.reflections.values.find do |reflection|
        reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection) &&
        reflection.foreign_key.to_sym == foreign_key.to_sym
      end
    end

    # Populate parent relationships from URL parameters
    # @param record [ActiveRecord::Base] The record to populate
    def populate_parent_relationships(record)
      detect_parent_filters.each do |foreign_key, parent_id|
        if valid_parent_filter?(foreign_key) && record.public_send(foreign_key).blank?
          record.public_send("#{foreign_key}=", parent_id)
        end
      end
    end

    # Determine redirect path after create based on context
    # @return [String] The redirect path
    def redirect_after_create_path
      if @parent_context
        # Redirect back to filtered index view
        url_for(action: :index, @parent_context[:foreign_key] => @parent_context[:record].id)
      else
        # Standard redirect to show page
        polymorphic_path(@record)
      end
    end
  end
end
