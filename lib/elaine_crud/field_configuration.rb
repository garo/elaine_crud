# frozen_string_literal: true

module ElaineCrud
  # Configuration class for individual field customization
  # Supports both hash-style and block-style DSL configuration
  class FieldConfiguration
    attr_accessor :field_name, :title, :description, :readonly, :default_value,
                  :display_callback, :edit_callback, :options, :foreign_key_config,
                  :grid_column_span, :grid_row_span

    def initialize(field_name, **options)
      @field_name = field_name
      
      # Set defaults
      @title = options.fetch(:title, field_name.to_s.humanize)
      @description = options.fetch(:description, nil)
      @readonly = options.fetch(:readonly, false)
      @default_value = options.fetch(:default_value, nil)
      @display_callback = options.fetch(:display_as, nil)
      @edit_callback = options.fetch(:edit_as, nil)
      @options = options.fetch(:options, nil)
      @foreign_key_config = options.fetch(:foreign_key, nil)
      @grid_column_span = options.fetch(:grid_column_span, 1)
      @grid_row_span = options.fetch(:grid_row_span, 1)
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

    def options(list = nil)
      return @options if list.nil?
      @options = list
    end

    def foreign_key(**config)
      return @foreign_key_config if config.empty?
      @foreign_key_config = config
    end

    def grid_column_span(value = nil)
      return @grid_column_span if value.nil?
      @grid_column_span = value
    end

    def grid_row_span(value = nil)
      return @grid_row_span if value.nil?
      @grid_row_span = value
    end

    # Helper methods for checking configuration state
    def has_options?
      @options.present?
    end

    def has_foreign_key?
      @foreign_key_config.present?
    end

    def has_custom_display?
      @display_callback.present?
    end

    def has_custom_edit?
      @edit_callback.present?
    end

    # Method to execute display callback
    def render_display_value(record, controller_instance)
      field_value = record.public_send(@field_name)
      
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
        result = @display_callback.call(field_value, record)
      else
        raise ArgumentError, "Display callback must be a Symbol or Proc, got #{@display_callback.class.name}"
      end
      
      # Ensure result is HTML safe
      result.respond_to?(:html_safe) ? result.html_safe : result.to_s.html_safe
    rescue => e
      # Graceful error handling - show the error in development but fallback in production
      if Rails.env.development?
        controller_instance.content_tag(:span, "Error: #{e.message}", class: "text-red-500 text-xs")
      else
        field_value.to_s.html_safe
      end
    end

    # Method to execute edit callback  
    def render_edit_field(record, controller_instance, form_builder = nil)
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
        result = @edit_callback.call(field_value, record, form_builder)
      else
        raise ArgumentError, "Edit callback must be a Symbol or Proc, got #{@edit_callback.class.name}"
      end
      
      # Ensure result is HTML safe
      result.respond_to?(:html_safe) ? result.html_safe : result.to_s.html_safe
    rescue => e
      # Graceful error handling - show the error in development but fallback in production
      if Rails.env.development?
        controller_instance.content_tag(:span, "Error: #{e.message}", class: "text-red-500 text-xs")
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
      # TODO: Implement foreign key option loading
      # 1. Validate @foreign_key_config has required keys (:model)
      # 2. Get target model: @foreign_key_config[:model]
      # 3. Apply scope if provided: @foreign_key_config[:scope]&.call || target_model.all
      # 4. Format options for select:
      #    - If display is Symbol: call method on each record
      #    - If display is Proc: call with each record
      #    - Default: call to_s on each record
      # 5. Add null option if configured: @foreign_key_config[:null_option]
      # 6. Return array of [display_text, value] pairs suitable for options_for_select
      return [] # Placeholder
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
  end
end