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
      # Handle virtual fields that don't exist on the model
      unless record.respond_to?(column)
        return content_tag(:span, 'Virtual field', class: 'text-gray-400')
      end
      
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
    # @param context [Symbol] The display context (:index or :show)
    # @return [String] The formatted value
    def display_field_value(record, field_name, context: :index)
      config = controller.field_config_for(field_name)

      # Handle has_many relationships
      if config&.has_has_many? || is_has_many_relationship?(record, field_name)
        return display_has_many_value(record, field_name, config)
      end

      # Handle has_one relationships
      if config&.has_has_one? || is_has_one_relationship?(record, field_name)
        return display_has_one_value(record, field_name, config)
      end

      # If field has custom display configuration, use it first (allows overriding defaults)
      if config&.has_custom_display?
        return config.render_display_value(record, controller)
      # Handle has_and_belongs_to_many relationships with default display
      elsif config&.has_habtm? || is_habtm_relationship?(record, field_name)
        return display_habtm_field(record, field_name, config, context: context)
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

    # Display has_many relationship value
    # @param record [ActiveRecord::Base] The record to display
    # @param field_name [Symbol] The field name
    # @param config [FieldConfiguration] The field configuration
    # @return [String] The formatted has_many value
    def display_has_many_value(record, field_name, config)
      if config&.has_has_many?
        # Use configuration to render
        display_text = config.render_has_many_display(record, controller)
        foreign_key = config.has_many_config[:foreign_key]
        related_model_controller = config.has_many_config[:model].name.underscore.pluralize

        link_to display_text,
                url_for(controller: related_model_controller, action: :index, foreign_key => record.id),
                class: "text-blue-600 hover:text-blue-800 underline",
                data: { turbo_frame: "_top" }
      else
        # Fallback for auto-detected has_many
        related_records = record.public_send(field_name)
        count = related_records.respond_to?(:count) ? related_records.count : 0

        if count > 0
          related_model = field_name.to_s.classify
          controller_name = field_name.to_s
          foreign_key = "#{record.class.name.underscore}_id"

          link_to "#{count} #{field_name.to_s.humanize.downcase}",
                  url_for(controller: controller_name, action: :index, foreign_key => record.id),
                  class: "text-blue-600 hover:text-blue-800 underline",
                  data: { turbo_frame: "_top" }
        else
          content_tag(:span, "No #{field_name.to_s.humanize.downcase}", class: 'text-gray-400')
        end
      end
    rescue => e
      Rails.logger.error "ElaineCrud: Error rendering has_many field #{field_name}: #{e.message}"
      content_tag(:span, "Error loading relationship", class: 'text-red-400')
    end

    # Check if field is a has_one relationship
    def is_has_one_relationship?(record, field_name)
      reflection = record.class.reflections[field_name.to_s]
      reflection&.is_a?(ActiveRecord::Reflection::HasOneReflection)
    end

    # Display has_one relationship value
    def display_has_one_value(record, field_name, config)
      if config&.has_has_one?
        config.render_has_one_display(record, controller)
      else
        # Fallback for auto-detected has_one
        related_record = record.public_send(field_name)

        if related_record.nil?
          content_tag(:span, '—', class: 'text-gray-400')
        else
          # Try to find a good display field
          display_field = controller.send(:determine_display_field_for_model, related_record.class)
          related_record.public_send(display_field).to_s
        end
      end
    rescue => e
      Rails.logger.error "ElaineCrud: Error rendering has_one field #{field_name}: #{e.message}"
      content_tag(:span, "Error loading relationship", class: 'text-red-400')
    end

    # Check if field is a has_many relationship
    def is_has_many_relationship?(record, field_name)
      reflection = record.class.reflections[field_name.to_s]
      reflection&.is_a?(ActiveRecord::Reflection::HasManyReflection)
    end

    # Check if field is a has_and_belongs_to_many relationship
    def is_habtm_relationship?(record, field_name)
      reflection = record.class.reflections[field_name.to_s]
      reflection&.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)
    end

    # Display HABTM field value - minimal implementation
    # Applications should use display_as for custom rendering
    # @param record [ActiveRecord::Base] The record to display
    # @param field_name [Symbol] The field name
    # @param config [FieldConfiguration] The field configuration
    # @return [String] The formatted HABTM value
    def display_habtm_field(record, field_name, config, context: :index)
      related_records = record.public_send(field_name)

      return content_tag(:span, "—", class: "text-gray-400") if related_records.empty?

      # Get configuration
      habtm_config = config&.habtm_config || {}
      display_field = habtm_config[:display_field] || :name

      # Determine the model class for the association
      association_name = field_name.to_s.singularize
      model_class = association_name.classify.constantize rescue nil

      # In show context, display full list with links
      if context == :show && model_class
        items_html = related_records.map do |r|
          display_value = r.public_send(display_field)
          link_to(display_value, polymorphic_path(r), class: "text-blue-600 hover:text-blue-800 hover:underline", data: { turbo_frame: "_top" })
        end

        # Join with commas and proper spacing
        safe_join(items_html, ", ")
      else
        # In index context, use compact display: comma-separated list of first few items
        preview_items = related_records.first(3).map { |r| r.public_send(display_field) }
        preview_text = preview_items.join(", ")
        preview_text += ", ..." if related_records.count > 3

        content_tag(:span, preview_text, class: "text-sm text-gray-900")
      end
    rescue => e
      Rails.logger.error "ElaineCrud: Error rendering HABTM field #{field_name}: #{e.message}"
      content_tag(:span, "Error loading relationships", class: 'text-red-400')
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
    def render_form_field(form, record, field_name, has_error: false)
      config = controller.field_config_for(field_name)

      # If field is readonly, show the display value instead of an input
      if field_readonly?(field_name)
        content_tag(:div, display_field_value(record, field_name),
                   class: "px-3 py-2 bg-gray-100 border border-gray-500 text-gray-600")
      # has_many associations are readonly in edit forms - show display value
      elsif config&.has_has_many?
        content_tag(:div, display_field_value(record, field_name),
                   class: "px-3 py-2 bg-gray-100 border border-gray-500 text-gray-600")
      # has_one associations are readonly in edit forms - show display value
      elsif config&.has_has_one?
        content_tag(:div, display_field_value(record, field_name),
                   class: "px-3 py-2 bg-gray-100 border border-gray-500 text-gray-600")
      # has_and_belongs_to_many associations - render checkboxes
      elsif config&.has_habtm? || is_habtm_relationship?(record, field_name)
        render_habtm_field(form, record, field_name, config, has_error: has_error)
      elsif config&.has_edit_partial?
        # Render using partial
        render_partial_edit_field(config, record, form, field_name)
      elsif config&.has_custom_edit?
        # Render using custom edit callback
        render_custom_edit_field(config, record, form, self)
      elsif config&.has_options?
        # Render options dropdown
        render_options_field(form, field_name, config, has_error: has_error)
      elsif config&.has_foreign_key?
        # Render foreign key dropdown
        render_foreign_key_field(form, field_name, config, has_error: has_error)
      else
        # Default form field based on ActiveRecord column type
        render_default_form_field(form, record, field_name, has_error: has_error)
      end
    end

    # Render default form field based on ActiveRecord column type
    # @param form [ActionView::Helpers::FormBuilder] The form builder
    # @param record [ActiveRecord::Base] The record
    # @param field_name [Symbol] The field name
    # @param has_error [Boolean] Whether the field has a validation error
    # @return [String] HTML-safe form field
    def render_default_form_field(form, record, field_name, has_error: false)
      column = record.class.columns.find { |c| c.name == field_name.to_s }

      # Error styling: red border for invalid fields, gray for valid
      border_color = has_error ? "border-red-500 focus:border-red-700" : "border-gray-500 focus:border-gray-700"
      field_class = "block w-full border #{border_color} text-sm bg-white px-3 py-2"

      # Check if this is a foreign key (integer field ending in _id with a belongs_to association)
      if column&.type == :integer && field_name.to_s.end_with?('_id')
        reflection = find_belongs_to_reflection_for_foreign_key(record.class, field_name)
        if reflection
          # Render as select box for foreign key
          return render_auto_foreign_key_field(form, field_name, reflection, has_error: has_error)
        end
      end

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

    # Render partial edit field using configured partial
    # @param config [FieldConfiguration] The field configuration
    # @param record [ActiveRecord::Base] The record
    # @param form [ActionView::Helpers::FormBuilder] The form builder
    # @param field_name [Symbol] The field name
    # @return [String] HTML-safe form field
    def render_partial_edit_field(config, record, form, field_name)
      field_value = record.public_send(field_name)
      
      begin
        render partial: config.edit_partial, locals: {
          form: form,
          record: record,
          field_name: field_name,
          field_value: field_value,
          config: config
        }
      rescue => e
        # Graceful error handling - show error in development
        if Rails.env.development?
          content_tag(:div, class: "text-red-500 text-xs border border-red-300 p-2 bg-red-50") do
            concat(content_tag(:strong, "Partial Error: "))
            concat("Could not render partial '#{config.edit_partial}': #{e.message}")
          end
        else
          # Fallback to default form field in production
          render_default_form_field(form, record, field_name)
        end
      end
    end

    # Render custom edit field using configuration callback
    # @param config [FieldConfiguration] The field configuration
    # @param record [ActiveRecord::Base] The record
    # @param form [ActionView::Helpers::FormBuilder] The form builder
    # @param view_context [ActionView::Base] The view context
    # @return [String] HTML-safe form field
    def render_custom_edit_field(config, record, form, view_context = nil)
      field_value = record.public_send(config.field_name)
      
      if config.edit_callback.is_a?(Symbol)
        # Call method on controller instance
        if controller.respond_to?(config.edit_callback, true)
          controller.send(config.edit_callback, field_value, record, form)
        else
          # Fallback to default if method not found
          render_default_form_field(form, record, config.field_name)
        end
      else
        # Use the FieldConfiguration's render method which handles view context
        config.render_edit_field(record, controller, form, view_context)
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
    def render_options_field(form, field_name, config, has_error: false)
      border_color = has_error ? "border-red-500 focus:border-red-700" : "border-gray-500 focus:border-gray-700"
      field_class = "block w-full border #{border_color} text-sm bg-white px-3 py-2"

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
    def render_foreign_key_field(form, field_name, config, has_error: false)
      border_color = has_error ? "border-red-500 focus:border-red-700" : "border-gray-500 focus:border-gray-700"
      field_class = "block w-full border #{border_color} text-sm bg-white px-3 py-2"

      # Get the current value of the field to pre-select it
      current_value = form.object.public_send(field_name)
      options = foreign_key_options_for_field(field_name, current_value)

      form.select(field_name, options,
                 { include_blank: config.foreign_key_config[:null_option] || "Select..." },
                 { class: field_class })
    end

    # Get foreign key options for a specific field
    # @param field_name [Symbol] The field name
    # @param selected_value [Object] The value to pre-select in the dropdown
    # @return [Array] Options suitable for select dropdown
    def foreign_key_options_for_field(field_name, selected_value = nil)
      config = controller.field_config_for(field_name)
      return [] unless config&.has_foreign_key?
      
      # Use the new foreign_key_options method from FieldConfiguration
      options = config.foreign_key_options(controller)
      options_for_select(options, selected_value)
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
    
    # Get grid column span for a field (for CSS grid layouts)
    # @param field_name [Symbol] The field name
    # @return [Integer] Number of columns this field should span
    def field_grid_column_span(field_name)
      config = controller.field_config_for(field_name)

      # Check if field configuration specifies a column span
      if config&.respond_to?(:grid_column_span) && config.grid_column_span
        config.grid_column_span
      else
        # Default column span based on field type or configuration
        case field_name.to_s
        when /description|note|comment|content/i
          # Text fields typically span more columns
          2
        else
          # Default single column
          1
        end
      end
    end

    # Get CSS classes for grid field layout
    # @param field_name [Symbol] The field name
    # @return [String] CSS classes for grid column styling
    def field_grid_classes(field_name)
      span = field_grid_column_span(field_name)
      classes = []

      # Add column span class if greater than 1
      classes << "col-span-#{span}" if span > 1

      classes.join(' ')
    end

    # Find belongs_to reflection for a foreign key field
    # @param model_class [Class] The ActiveRecord model class
    # @param foreign_key [Symbol] The foreign key field name
    # @return [ActiveRecord::Reflection::BelongsToReflection, nil] The reflection or nil
    def find_belongs_to_reflection_for_foreign_key(model_class, foreign_key)
      model_class.reflections.values.find do |reflection|
        reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection) &&
        reflection.foreign_key.to_sym == foreign_key.to_sym
      end
    end

    # Render auto-detected foreign key field as select box
    # @param form [ActionView::Helpers::FormBuilder] The form builder
    # @param field_name [Symbol] The field name
    # @param reflection [ActiveRecord::Reflection::BelongsToReflection] The belongs_to reflection
    # @param has_error [Boolean] Whether the field has a validation error
    # @return [String] HTML-safe form field
    def render_auto_foreign_key_field(form, field_name, reflection, has_error: false)
      border_color = has_error ? "border-red-500 focus:border-red-700" : "border-gray-500 focus:border-gray-700"
      field_class = "block w-full border #{border_color} text-sm bg-white px-3 py-2"

      begin
        # Get the related model class
        related_model = reflection.klass

        # Determine display field for the related model
        display_field = controller.send(:determine_display_field_for_model, related_model)

        # Get all records for the dropdown
        records = related_model.all.order(display_field)
        options = records.map { |r| [r.public_send(display_field), r.id] }

        # Get current value to pre-select
        current_value = form.object.public_send(field_name)

        form.select(field_name, options,
                   { include_blank: "Select..." },
                   { class: field_class })
      rescue => e
        # If there's an error loading the related model, fall back to number input
        Rails.logger.warn "ElaineCrud: Could not render foreign key select for #{field_name}: #{e.message}" if Rails.env.development?
        form.number_field(field_name, class: field_class)
      end
    end

    # Render HABTM field for forms (checkboxes)
    # @param form [ActionView::Helpers::FormBuilder] The form builder
    # @param record [ActiveRecord::Base] The record being edited
    # @param field_name [Symbol] The field name
    # @param config [FieldConfiguration] The field configuration
    # @param has_error [Boolean] Whether the field has a validation error
    # @return [String] HTML-safe form field
    def render_habtm_field(form, record, field_name, config, has_error: false)
      reflection = record.class.reflections[field_name.to_s]
      related_model = reflection.klass

      # Get configuration or use defaults
      habtm_config = config&.habtm_config || {}
      display_field = habtm_config[:display_field] || :name

      # Get all available records
      all_records = related_model.all.order(display_field)

      # Get currently selected IDs
      selected_ids = record.public_send(field_name).pluck(:id)

      # Add hidden field to ensure empty array is submitted when no checkboxes are checked
      hidden_field = hidden_field_tag("#{record.class.name.underscore}[#{field_name.to_s.singularize}_ids][]", "", id: nil)

      # Error styling for checkbox container
      border_color = has_error ? "border-red-500" : "border-gray-300"

      # Render checkboxes in a scrollable container
      hidden_field.html_safe + content_tag(:div, class: "space-y-2 max-h-64 overflow-y-auto border #{border_color} rounded p-3 bg-white") do
        all_records.map do |related_record|
          checkbox_id = "#{record.class.name.underscore}_#{field_name.to_s.singularize}_ids_#{related_record.id}"

          content_tag(:div, class: "flex items-center") do
            label_text = related_record.public_send(display_field)

            concat check_box_tag(
              "#{record.class.name.underscore}[#{field_name.to_s.singularize}_ids][]",
              related_record.id,
              selected_ids.include?(related_record.id),
              id: checkbox_id,
              class: "h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            )
            concat label_tag(checkbox_id, label_text, class: "ml-2 text-sm text-gray-700")
          end
        end.join.html_safe
      end
    rescue => e
      Rails.logger.error "ElaineCrud: Error rendering HABTM form field #{field_name}: #{e.message}"
      content_tag(:span, "Error loading form field", class: 'text-red-400')
    end
  end
end