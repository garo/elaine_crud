# frozen_string_literal: true

module ElaineCrud
  # Configuration class for individual field customization
  # Supports both hash-style and block-style DSL configuration
  class FieldConfiguration
    attr_accessor :field_name, :title, :description, :readonly, :default_value,
                  :display_callback, :edit_callback, :edit_partial, :options, :foreign_key_config,
                  :has_many_config, :has_one_config, :visible, :grid_column_span,
                  :searchable, :filterable, :filter_type

    def initialize(field_name, **options)
      @field_name = field_name

      # Set defaults
      @title = options.fetch(:title, field_name.to_s.humanize)
      @description = options.fetch(:description, nil)
      @readonly = options.fetch(:readonly, false)
      @default_value = options.fetch(:default_value, nil)
      @display_callback = options.fetch(:display_as, nil)
      @edit_callback = options.fetch(:edit_as, nil)
      @edit_partial = options.fetch(:edit_partial, nil)
      @options = options.fetch(:options, nil)
      @foreign_key_config = options.fetch(:foreign_key, nil)
      @has_many_config = options.fetch(:has_many, nil)
      @has_one_config = options.fetch(:has_one, nil)
      @visible = options.fetch(:visible, nil)
      @grid_column_span = options.fetch(:grid_column_span, nil)
      @searchable = options.fetch(:searchable, nil)
      @filterable = options.fetch(:filterable, nil)
      @filter_type = options.fetch(:filter_type, nil)
    end

    # Block-style DSL methods
    def title(value = nil)
      return @title if value.nil?
      @title = value
    end

    def description(value = nil)
      return @description if value.nil?
      @description = value
    end

    def readonly(value = nil)
      return @readonly if value.nil?
      @readonly = value
    end

    def default_value(value = nil)
      return @default_value if value.nil?
      @default_value = value
    end

    def display_as(callback = nil, &block)
      return @display_callback if callback.nil? && block.nil?
      @display_callback = callback || block
    end

    def edit_as(callback = nil, &block)
      return @edit_callback if callback.nil? && block.nil?
      @edit_callback = callback || block
    end

    def edit_partial(partial_path = nil)
      return @edit_partial if partial_path.nil?
      @edit_partial = partial_path
    end

    def options(list = nil)
      return @options if list.nil?
      @options = list
    end

    def foreign_key(**config)
      return @foreign_key_config if config.empty?
      @foreign_key_config = config
    end

    def has_many(**config)
      return @has_many_config if config.empty?
      @has_many_config = config
    end

    def has_one(**config)
      return @has_one_config if config.empty?
      @has_one_config = config
    end

    def visible(value = nil)
      return @visible if value.nil?
      @visible = value
    end
    
    def grid_column_span(value = nil)
      return @grid_column_span if value.nil?
      @grid_column_span = value
    end

    def searchable(value = nil)
      return @searchable if value.nil?
      @searchable = value
    end

    def filterable(value = nil)
      return @filterable if value.nil?
      @filterable = value
    end

    def filter_type(value = nil)
      return @filter_type if value.nil?
      @filter_type = value
    end

    # Helper methods for checking configuration state
    def has_options?
      @options.present?
    end

    def has_foreign_key?
      @foreign_key_config.present?
    end

    def has_has_many?
      @has_many_config.present?
    end

    def has_has_one?
      @has_one_config.present?
    end

    def has_custom_display?
      @display_callback.present?
    end

    def has_custom_edit?
      @edit_callback.present?
    end

    def has_edit_partial?
      @edit_partial.present?
    end

    # Method to execute display callback
    def render_display_value(record, controller_instance)
      # For virtual fields (those that don't exist on the model), use nil as field_value
      field_value = if record.respond_to?(@field_name)
                     record.public_send(@field_name)
                   else
                     nil
                   end
      
      case @display_callback
      when Symbol
        # Call method on controller instance
        if controller_instance.respond_to?(@display_callback, true)
          result = controller_instance.send(@display_callback, field_value, record)
        else
          raise NoMethodError, "Display callback method '#{@display_callback}' not found on #{controller_instance.class.name}"
        end
      when Proc
        # Call proc with field value and record
        # Execute the lambda with the controller that has access to helpers
        result = controller_instance.instance_exec(field_value, record, &@display_callback)
      else
        raise ArgumentError, "Display callback must be a Symbol or Proc, got #{@display_callback.class.name}"
      end
      
      # Ensure result is HTML safe
      result.respond_to?(:html_safe) ? result.html_safe : result.to_s.html_safe
    rescue => e
      # Graceful error handling - show the error in development but fallback in production
      if Rails.env.development?
        %Q{<span class="text-red-500 text-xs">Error: #{e.message}</span>}.html_safe
      else
        field_value.to_s.html_safe
      end
    end

    # Method to execute edit callback  
    def render_edit_field(record, controller_instance, form_builder = nil, view_context = nil)
      field_value = record.public_send(@field_name)
      
      case @edit_callback
      when Symbol
        # Call method on controller instance
        if controller_instance.respond_to?(@edit_callback, true)
          result = controller_instance.send(@edit_callback, field_value, record, form_builder)
        else
          raise NoMethodError, "Edit callback method '#{@edit_callback}' not found on #{controller_instance.class.name}"
        end
      when Proc
        # Call proc with field value, record, and form builder
        if view_context
          # Execute the lambda in the view context so it has access to helpers
          result = view_context.instance_exec(field_value, record, form_builder, &@edit_callback)
        else
          # Fallback to direct call for backward compatibility
          result = @edit_callback.call(field_value, record, form_builder)
        end
      else
        raise ArgumentError, "Edit callback must be a Symbol or Proc, got #{@edit_callback.class.name}"
      end
      
      # Ensure result is HTML safe
      result.respond_to?(:html_safe) ? result.html_safe : result.to_s.html_safe
    rescue => e
      # Graceful error handling - show the error in development but fallback in production
      if Rails.env.development?
        if view_context
          view_context.content_tag(:span, "Error: #{e.message}", class: "text-red-500 text-xs")
        else
          %Q{<span class="text-red-500 text-xs">Error: #{e.message}</span>}.html_safe
        end
      else
        # Fallback to basic text field
        if form_builder
          field_class = "block w-full border-gray-300 rounded-md shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
          form_builder.text_field(@field_name, class: field_class)
        else
          field_value.to_s.html_safe
        end
      end
    end

    # Method to get foreign key options for dropdowns
    def foreign_key_options(controller_instance)
      return [] unless has_foreign_key?
      
      # Validate required configuration
      target_model = @foreign_key_config[:model]
      return [] unless target_model
      
      # Get records using scope if provided, otherwise all records
      records = if @foreign_key_config[:scope]
        @foreign_key_config[:scope].call
      else
        target_model.all
      end
      
      # Format options for select dropdown
      options = records.map do |record|
        display_value = case @foreign_key_config[:display]
        when Symbol
          record.respond_to?(@foreign_key_config[:display]) ? 
            record.public_send(@foreign_key_config[:display]) : 
            record.to_s
        when Proc
          @foreign_key_config[:display].call(record)
        else
          record.to_s
        end
        
        [display_value, record.id]
      end
      
      options
    rescue => e
      # Graceful error handling
      if Rails.env.development?
        [["Error: #{e.message}", ""]]
      else
        []
      end
    end

    # Method to get default value for new records
    def resolve_default_value(controller_instance)
      # TODO: Implement default value resolution
      # 1. Return nil if @default_value is nil
      # 2. If @default_value is a Proc or Lambda, call it with controller_instance as context
      # 3. If @default_value is any other value, return it directly
      # 4. Handle edge cases and ensure returned value is appropriate for the field type
      return @default_value if @default_value.present? && !@default_value.respond_to?(:call)
      return nil # Placeholder for callable defaults
    end

    # Helper method to determine if field should be shown in index
    def show_in_index?
      # TODO: Implement index visibility logic
      # Default: show all fields except id and timestamps
      # Could be configurable in future: @show_in_index boolean
      !%w[id created_at updated_at].include?(@field_name.to_s)
    end

    # Helper method to determine if field should be shown in forms
    def show_in_form?
      # TODO: Implement form visibility logic  
      # Default: show all permitted params except readonly fields in edit mode
      # Could be configurable in future: @show_in_form boolean
      !@readonly
    end

    # Helper method to get field input type for default rendering
    def default_input_type(column_type)
      # TODO: Implement default input type mapping
      # Map ActiveRecord column types to HTML input types:
      # - :string, :text -> text_field / text_area
      # - :integer, :decimal, :float -> number_field
      # - :boolean -> check_box
      # - :date -> date_field
      # - :datetime, :timestamp -> datetime_local_field
      # - etc.
      case column_type
      when :string then :text_field
      when :text then :text_area
      when :integer, :decimal, :float then :number_field
      when :boolean then :check_box
      when :date then :date_field
      when :datetime, :timestamp then :datetime_local_field
      else :text_field
      end
    end

    # Get options for has_many relationship display
    def has_many_related_records(controller_instance)
      return [] unless has_has_many?
      
      model_class = @has_many_config[:model]
      foreign_key = @has_many_config[:foreign_key]
      
      # This would be called from a parent record context
      parent_record = controller_instance.instance_variable_get(:@record)
      return [] unless parent_record
      
      related_records = parent_record.public_send(@field_name)
      
      # Apply scope if specified
      if @has_many_config[:scope]
        related_records = related_records.instance_eval(&@has_many_config[:scope])
      end
      
      related_records
    end

    # Get display value for has_many relationship
    def render_has_many_display(record, controller_instance)
      return "" unless has_has_many?

      related_records = record.public_send(@field_name)

      if @has_many_config[:show_count]
        count = related_records.count

        if @has_many_config[:max_preview_items] && @has_many_config[:max_preview_items] > 0
          preview_records = related_records.limit(@has_many_config[:max_preview_items])
          display_field = @has_many_config[:display] || :id

          preview_text = preview_records.map do |rel_record|
            begin
              if display_field.is_a?(Proc)
                display_field.call(rel_record)
              else
                result = rel_record.public_send(display_field)
                result || "N/A"
              end
            rescue => e
              Rails.logger.error "ElaineCrud: Error calling #{display_field} on #{rel_record.class.name}##{rel_record.id}: #{e.message}"
              "Error"
            end
          end.join(", ")

          "#{count} items#{count > 0 ? ": #{preview_text}" : ""}"
        else
          "#{count} items"
        end
      else
        related_records.count.to_s
      end
    rescue => e
      Rails.logger.error "ElaineCrud: Error rendering has_many display: #{e.message}"
      "Error loading relationships"
    end

    # Get display value for has_one relationship
    def render_has_one_display(record, controller_instance)
      return "" unless has_has_one?

      related_record = record.public_send(@field_name)
      return "—" if related_record.nil?

      display_field = @has_one_config[:display] || :id

      begin
        if display_field.is_a?(Proc)
          display_field.call(related_record)
        else
          result = related_record.public_send(display_field)
          result || "N/A"
        end
      rescue => e
        Rails.logger.error "ElaineCrud: Error calling #{display_field} on #{related_record.class.name}##{related_record.id}: #{e.message}"
        "Error"
      end
    rescue => e
      Rails.logger.error "ElaineCrud: Error rendering has_one display: #{e.message}"
      "Error loading relationship"
    end
  end
end