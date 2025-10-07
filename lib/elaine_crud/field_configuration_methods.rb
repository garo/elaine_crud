# frozen_string_literal: true

module ElaineCrud
  # Instance methods for accessing and working with field configurations
  # Provides runtime access to field metadata and rendering
  module FieldConfigurationMethods
    extend ActiveSupport::Concern

    # Get configuration for a specific field
    # @param field_name [Symbol] The field name
    # @return [FieldConfiguration, nil] The configuration or nil if not configured
    def field_config_for(field_name)
      field_configurations&.dig(field_name.to_sym)
    end

    # Get all configured field names
    # @return [Array<Symbol>] List of configured field names
    def configured_fields
      field_configurations&.keys || []
    end

    # Check if a field has custom configuration
    # @param field_name [Symbol] The field name
    # @return [Boolean] True if field has custom configuration
    def field_configured?(field_name)
      field_config_for(field_name).present?
    end

    # Get display title for a field
    # @param field_name [Symbol] The field name
    # @return [String] The display title (configured or humanized)
    def field_title(field_name)
      config = field_config_for(field_name)
      config&.title || field_name.to_s.humanize
    end

    # Get description for a field
    # @param field_name [Symbol] The field name
    # @return [String, nil] The field description if configured
    def field_description(field_name)
      field_config_for(field_name)&.description
    end

    # Check if a field is readonly
    # @param field_name [Symbol] The field name
    # @return [Boolean] True if field is readonly
    def field_readonly?(field_name)
      field_config_for(field_name)&.readonly || false
    end

    # Check if Turbo frames are disabled for this controller
    # @return [Boolean] True if Turbo frames are disabled
    def turbo_disabled?
      disable_turbo_frames == true
    end

    # Render display value for a field
    # @param record [ActiveRecord::Base] The record
    # @param field_name [Symbol] The field name
    # @return [String] HTML safe string for display
    def render_field_display(record, field_name)
      # Delegate to helper which has access to view context
      helpers.display_field_value(record, field_name)
    end

    # Render edit field for a form
    # @param record [ActiveRecord::Base] The record
    # @param field_name [Symbol] The field name
    # @param form_builder [ActionView::Helpers::FormBuilder, nil] Optional form builder
    # @return [String] HTML safe string for form field
    def render_field_edit(record, field_name, form_builder = nil)
      config = field_config_for(field_name)

      return readonly_field_display(record, field_name) if field_readonly?(field_name)

      if config&.has_custom_edit?
        config.render_edit_field(record, self, form_builder)
      else
        # TODO: Implement fallback to default edit field logic
        # Should generate appropriate form fields based on field type
        # Should handle dropdowns for options, foreign key selects, etc.
        "<!-- TODO: Default edit field for #{field_name} -->" # Placeholder
      end
    end

    # Render readonly field display (for readonly fields in edit forms)
    # @param record [ActiveRecord::Base] The record
    # @param field_name [Symbol] The field name
    # @return [String] HTML safe string for readonly display
    def readonly_field_display(record, field_name)
      # TODO: Implement readonly field display
      # Should render the display value but in an edit form context
      # Maybe with a different styling to indicate it's not editable
      render_field_display(record, field_name) # Placeholder
    end

    # Instance method version of determine_display_field_for_model
    # @param model_class [Class] The ActiveRecord model class
    # @return [Symbol] The field to use for display
    def determine_display_field_for_model(model_class)
      # Common field names for display, in order of preference
      display_candidates = [:name, :title, :display_name, :full_name, :label, :description]

      # Check which columns exist
      column_names = model_class.column_names.map(&:to_sym)

      # Return the first matching candidate
      display_field = display_candidates.find { |candidate| column_names.include?(candidate) }

      # If none found, use the first string/text column that's not id, created_at, updated_at
      unless display_field
        string_columns = model_class.columns.select do |col|
          [:string, :text].include?(col.type) &&
          !%w[id created_at updated_at].include?(col.name)
        end
        display_field = string_columns.first&.name&.to_sym
      end

      # Final fallback to :id
      display_field || :id
    end

    # Apply default values to a new record based on field configurations
    # @param record [ActiveRecord::Base] The record to apply defaults to
    def apply_field_defaults(record)
      # TODO: Implement default value application
      # Should iterate through field configurations and apply default_value if present
      # Should handle both static values and proc/lambda callbacks
      # Should only apply to new records (record.new_record?)
      return record # Placeholder
    end

    # Debug method to help troubleshoot configuration issues
    # Call this in your controller in development to see the configuration
    def debug_configuration
      return unless Rails.env.development?

      puts "\n=== ElaineCrud Configuration Debug ==="
      puts "Model: #{crud_model&.name || 'NOT SET'}"
      puts "Permitted Attributes: #{permitted_attributes&.inspect || 'NOT SET'}"
      puts "Field Configurations: #{field_configurations&.keys&.inspect || 'NONE'}"

      if crud_model
        reflections = crud_model.reflections.select { |_, r| r.is_a?(ActiveRecord::Reflection::BelongsToReflection) }
        puts "Belongs_to relationships: #{reflections.keys.inspect}"
        puts "Foreign keys: #{reflections.values.map(&:foreign_key).inspect}"
      end

      puts "====================================\n"
    end
  end
end
