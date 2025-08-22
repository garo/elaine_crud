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
      foreign_key_value = record.public_send(field_name)
      return content_tag(:span, '—', class: 'text-gray-400') if foreign_key_value.blank?
      
      foreign_key_config = config.foreign_key_config
      target_model = foreign_key_config[:model]
      return foreign_key_value.to_s unless target_model
      
      # Load the related record
      related_record = target_model.find_by(id: foreign_key_value)
      return content_tag(:span, "Not found (ID: #{foreign_key_value})", class: 'text-red-400') unless related_record
      
      # Apply display callback if configured
      display_value = case foreign_key_config[:display]
      when Symbol
        related_record.respond_to?(foreign_key_config[:display]) ? 
          related_record.public_send(foreign_key_config[:display]) : 
          related_record.to_s
      when Proc
        foreign_key_config[:display].call(related_record)
      else
        related_record.to_s
      end
      
      display_value.to_s.html_safe
    rescue => e
      # Graceful error handling
      if Rails.env.development?
        content_tag(:span, "Error: #{e.message}", class: 'text-red-500 text-xs')
      else
        foreign_key_value.to_s
      end
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
                   class: "px-3 py-2 bg-gray-100 border border-gray-500 text-gray-600")
      elsif config&.has_custom_edit?
        # Render using custom edit callback
        render_custom_edit_field(config, record, form)
      elsif config&.has_options?
        # Render options dropdown
        render_options_field(form, field_name, config)
      elsif config&.has_foreign_key?
        # Render foreign key dropdown
        render_foreign_key_field(form, field_name, config)
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
      
      field_class = "block w-full border border-gray-500 focus:border-gray-700 text-sm bg-white px-3 py-2"
      
      case column&.type
      when :text
        form.text_area(field_name, class: "#{field_class} resize-vertical", rows: 3)
      when :boolean
        form.check_box(field_name, class: "border border-gray-500 focus:border-gray-700 w-4 h-4")
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

    # Render custom edit field using configuration callback
    # @param config [FieldConfiguration] The field configuration
    # @param record [ActiveRecord::Base] The record
    # @param form [ActionView::Helpers::FormBuilder] The form builder
    # @return [String] HTML-safe form field
    def render_custom_edit_field(config, record, form)
      field_value = record.public_send(config.field_name)
      
      case config.edit_callback
      when Symbol
        # Call method on controller instance
        if controller.respond_to?(config.edit_callback, true)
          controller.send(config.edit_callback, field_value, record, form)
        else
          # Fallback to default if method not found
          render_default_form_field(form, record, config.field_name)
        end
      when Proc
        # Call proc with field value, record, and form
        config.edit_callback.call(field_value, record, form)
      else
        # Fallback to default
        render_default_form_field(form, record, config.field_name)
      end
    rescue => e
      # Graceful error handling - show error in development
      if Rails.env.development?
        content_tag(:span, "Error: #{e.message}", class: "text-red-500 text-xs")
      else
        render_default_form_field(form, record, config.field_name)
      end
    end

    # Render options dropdown field
    # @param form [ActionView::Helpers::FormBuilder] The form builder
    # @param field_name [Symbol] The field name
    # @param config [FieldConfiguration] The field configuration
    # @return [String] HTML-safe form field
    def render_options_field(form, field_name, config)
      field_class = "block w-full border border-gray-500 focus:border-gray-700 text-sm bg-white px-3 py-2"
      
      # Handle both array and hash options
      options = case config.options
      when Array
        config.options.map { |opt| [opt.to_s.humanize, opt] }
      when Hash
        config.options.to_a
      else
        []
      end
      
      form.select(field_name, options, 
                 { include_blank: "Select..." }, 
                 { class: field_class })
    end

    # Render foreign key dropdown field
    # @param form [ActionView::Helpers::FormBuilder] The form builder
    # @param field_name [Symbol] The field name
    # @param config [FieldConfiguration] The field configuration
    # @return [String] HTML-safe form field
    def render_foreign_key_field(form, field_name, config)
      field_class = "block w-full border border-gray-500 focus:border-gray-700 text-sm bg-white px-3 py-2"
      
      options = foreign_key_options_for_field(field_name)
      
      form.select(field_name, options, 
                 { include_blank: config.foreign_key_config[:null_option] || "Select..." },
                 { class: field_class })
    end

    # Get foreign key options for a specific field
    # @param field_name [Symbol] The field name
    # @return [Array] Options suitable for select dropdown
    def foreign_key_options_for_field(field_name)
      config = controller.field_config_for(field_name)
      return [] unless config&.has_foreign_key?
      
      foreign_key_config = config.foreign_key_config
      target_model = foreign_key_config[:model]
      return [] unless target_model
      
      # Apply scope if provided, otherwise use all records
      records = if foreign_key_config[:scope]
        foreign_key_config[:scope].call
      else
        target_model.all
      end
      
      # Format options for select
      options = records.map do |record|
        display_value = case foreign_key_config[:display]
        when Symbol
          record.respond_to?(foreign_key_config[:display]) ? 
            record.public_send(foreign_key_config[:display]) : 
            record.to_s
        when Proc
          foreign_key_config[:display].call(record)
        else
          record.to_s
        end
        
        [display_value, record.id]
      end
      
      options_for_select(options)
    rescue => e
      # Graceful error handling
      if Rails.env.development?
        options_for_select([["Error: #{e.message}", ""]])
      else
        []
      end
    end

    private

    # Render field options for select dropdowns
    # @param field_name [Symbol] The field name
    # @return [Array] Options array suitable for options_for_select
    def field_options(field_name)
      config = controller.field_config_for(field_name)
      return [] unless config
      
      if config.has_options?
        case config.options
        when Array
          config.options.map { |opt| [opt.to_s.humanize, opt] }
        when Hash
          config.options.to_a
        else
          []
        end
      elsif config.has_foreign_key?
        # This will be handled by foreign_key_options_for_field method
        []
      else
        []
      end
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
    
    # Generate a sort URL for a column
    # @param column [Symbol] The column to sort by
    # @return [String] URL with sort parameters
    def sort_url_for(column)
      current_column = controller.current_sort_column
      current_direction = controller.current_sort_direction
      
      # If clicking on the same column, toggle direction
      if current_column.to_s == column.to_s
        new_direction = controller.toggle_sort_direction(current_direction)
      else
        # New column, default to ascending
        new_direction = :asc
      end
      
      # Preserve other parameters and add/update sort parameters
      url_params = request.params.except(:action, :controller).merge({
        sort: column,
        direction: new_direction
      })
      
      url_for(url_params)
    end
    
    # Check if a column is currently being sorted
    # @param column [Symbol] The column to check
    # @return [Boolean] True if this column is being sorted
    def column_sorted?(column)
      controller.current_sort_column.to_s == column.to_s
    end
    
    # Get sort direction for a column
    # @param column [Symbol] The column to check
    # @return [Symbol, nil] The sort direction if this column is sorted
    def column_sort_direction(column)
      column_sorted?(column) ? controller.current_sort_direction : nil
    end
    
    # Generate sort direction indicator (arrow) for column header
    # @param column [Symbol] The column to generate indicator for
    # @return [String] HTML for sort indicator
    def sort_indicator(column)
      return '' unless column_sorted?(column)
      
      direction = column_sort_direction(column)
      case direction
      when :asc
        content_tag(:span, '↑', class: 'text-blue-600 font-bold ml-1')
      when :desc
        content_tag(:span, '↓', class: 'text-blue-600 font-bold ml-1')
      else
        ''
      end
    end
    
    # Calculate layout structure for a record (helper method for views)
    # @param content [ActiveRecord::Base] The record being displayed
    # @param fields [Array<Symbol>] Array of field names to include in layout
    # @return [Array<Array<Hash>>] Nested array layout structure
    def calculate_layout(content, fields)
      controller.calculate_layout(content, fields)
    end
    
    # Calculate layout header structure (helper method for views)
    # @param fields [Array<Symbol>] Array of field names to include in layout
    # @return [Array<Hash>] Array of header config objects
    def calculate_layout_header(fields)
      controller.calculate_layout_header(fields)
    end
    
    # Get the title for a header column
    # @param header_config [Hash] Header config object
    # @return [String] The title to display
    def header_column_title(header_config)
      if header_config[:title]
        header_config[:title]
      elsif header_config[:field_name]
        field_title(header_config[:field_name])
      else
        ""
      end
    end
    
    # Check if a header column is sortable
    # @param header_config [Hash] Header config object
    # @return [Boolean] True if column has a field_name and is sortable
    def header_column_sortable?(header_config)
      header_config[:field_name].present?
    end
  end
end