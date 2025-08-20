# frozen_string_literal: true

module ElaineCrud
  module BaseHelper
    # Display the value of a column for a record (legacy method for backward compatibility)
    # This method can be overridden in the host application to customize display
    #
    # @param record [ActiveRecord::Base] The record to display
    # @param column [String] The column name to display
    # @return [String] The formatted value
    def display_column_value(record, column)
      value = record.public_send(column)
      
      case value
      when nil
        content_tag(:span, '—', class: 'text-gray-400')
      when true
        content_tag(:span, '✓', class: 'text-green-600 font-bold')
      when false
        content_tag(:span, '✗', class: 'text-red-600 font-bold')
      when Date, DateTime, Time
        value.strftime('%m/%d/%Y')
      else
        truncate(value.to_s, length: 50)
      end
    end

    # Display field value using new field configuration system
    # @param record [ActiveRecord::Base] The record to display
    # @param field_name [Symbol] The field name
    # @return [String] The formatted value
    def display_field_value(record, field_name)
      config = controller.field_config_for(field_name)
      
      # If field has custom display configuration, use it
      if config&.has_custom_display?
        config.render_display_value(record, controller)
      elsif config&.has_foreign_key?
        # TODO: Implement foreign key display logic
        # Should load the related record and format it according to foreign_key config
        display_foreign_key_value(record, field_name, config)
      else
        # Fall back to default display logic
        display_column_value(record, field_name.to_s)
      end
    end

    private

    # Display foreign key field value
    # @param record [ActiveRecord::Base] The record to display
    # @param field_name [Symbol] The field name
    # @param config [FieldConfiguration] The field configuration
    # @return [String] The formatted foreign key value
    def display_foreign_key_value(record, field_name, config)
      # TODO: Implement foreign key value display
      # 1. Get foreign key value: record.public_send(field_name)
      # 2. Return "—" if nil/blank
      # 3. Load related record: config.foreign_key_config[:model].find(foreign_key_value)
      # 4. Apply display callback if configured: config.foreign_key_config[:display]
      # 5. Fall back to to_s if no display callback
      # 6. Handle errors gracefully (record not found, etc.)
      
      foreign_key_value = record.public_send(field_name)
      return content_tag(:span, '—', class: 'text-gray-400') if foreign_key_value.blank?
      
      # Placeholder: just show the ID for now
      foreign_key_value.to_s
    end
    
    # Generate a human-readable title for the model
    # @param model_class [Class] The ActiveRecord model class
    # @return [String] Human-readable title
    def model_title(model_class)
      model_class.name.titleize
    end
    
    # Generate a human-readable field label (legacy method for backward compatibility)
    # @param field_name [String, Symbol] The field name
    # @return [String] Human-readable label
    def field_label(field_name)
      field_name.to_s.humanize
    end

    # Get field title using configuration system
    # @param field_name [Symbol] The field name
    # @return [String] The field title (configured or default)
    def field_title(field_name)
      controller.field_title(field_name)
    end

    # Get field description using configuration system
    # @param field_name [Symbol] The field name  
    # @return [String, nil] The field description if configured
    def field_description(field_name)
      controller.field_description(field_name)
    end

    # Render form field using field configuration system
    # @param form [ActionView::Helpers::FormBuilder] The form builder
    # @param record [ActiveRecord::Base] The record being edited
    # @param field_name [Symbol] The field name
    # @return [String] HTML-safe form field
    def render_form_field(form, record, field_name)
      config = controller.field_config_for(field_name)
      
      # If field is readonly, show the display value instead of an input
      if field_readonly?(field_name)
        content_tag(:div, display_field_value(record, field_name), 
                   class: "px-3 py-2 bg-gray-100 border border-gray-300 rounded text-gray-600")
      elsif config&.has_custom_edit?
        # TODO: Implement custom edit callback rendering
        config.render_edit_field(record, controller, form)
      elsif config&.has_options?
        # TODO: Implement options dropdown rendering  
        form.select(field_name, config.options, 
                   { include_blank: "Select..." }, 
                   { class: "form-select mt-1 block w-full border-gray-300 rounded-md shadow-sm" })
      elsif config&.has_foreign_key?
        # TODO: Implement foreign key dropdown rendering
        form.select(field_name, foreign_key_options_for_field(field_name), 
                   { include_blank: config.foreign_key_config[:null_option] || "Select..." },
                   { class: "form-select mt-1 block w-full border-gray-300 rounded-md shadow-sm" })
      else
        # Default form field based on ActiveRecord column type
        render_default_form_field(form, record, field_name)
      end
    end

    # Render default form field based on ActiveRecord column type
    # @param form [ActionView::Helpers::FormBuilder] The form builder
    # @param record [ActiveRecord::Base] The record
    # @param field_name [Symbol] The field name
    # @return [String] HTML-safe form field
    def render_default_form_field(form, record, field_name)
      column = record.class.columns.find { |c| c.name == field_name.to_s }
      
      field_class = "mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-blue-500 focus:ring-blue-500"
      
      case column&.type
      when :text
        form.text_area(field_name, class: "#{field_class} resize-vertical", rows: 3)
      when :boolean
        form.check_box(field_name, class: "rounded border-gray-300 text-blue-600 focus:ring-blue-500")
      when :date
        form.date_field(field_name, class: field_class)
      when :datetime, :timestamp
        form.datetime_local_field(field_name, class: field_class)
      when :integer, :decimal, :float
        form.number_field(field_name, class: field_class)
      else
        form.text_field(field_name, class: field_class)
      end
    end

    # Get foreign key options for a specific field
    # @param field_name [Symbol] The field name
    # @return [Array] Options suitable for select dropdown
    def foreign_key_options_for_field(field_name)
      # TODO: Implement foreign key options loading
      # This should call config.foreign_key_options(controller)
      []
    end

    private

    # Render field options for select dropdowns
    # @param field_name [Symbol] The field name
    # @return [Array] Options array suitable for options_for_select
    def field_options(field_name)
      # TODO: Implement field options loading
      # 1. Get field configuration: controller.field_config_for(field_name)
      # 2. If has options, return them: config.options
      # 3. If has foreign key, get foreign key options: config.foreign_key_options(controller)
      # 4. Return empty array if no options configured
      
      [] # Placeholder
    end

    # Check if field has dropdown options
    # @param field_name [Symbol] The field name
    # @return [Boolean] True if field has options
    def field_has_options?(field_name)
      config = controller.field_config_for(field_name)
      config&.has_options? || config&.has_foreign_key?
    end

    # Check if a field is readonly (helper method for views)
    # @param field_name [Symbol] The field name
    # @return [Boolean] True if field is readonly
    def field_readonly?(field_name)
      controller.field_readonly?(field_name)
    end

    # Get permitted attributes from controller (helper method for views)
    # @return [Array<Symbol>] List of permitted attributes
    def permitted_attributes
      controller.permitted_attributes
    end

    # Get model name from controller (helper method for views)
    # @return [String] The model name
    def model_name
      controller.model_name
    end
  end
end