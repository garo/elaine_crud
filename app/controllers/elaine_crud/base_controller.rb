# frozen_string_literal: true

module ElaineCrud
  # Base controller providing CRUD functionality for ActiveRecord models
  #
  # Usage:
  #   class PeopleController < ElaineCrud::BaseController
  #     model Person
  #     permit_params :name, :email, :phone
  #   end
  class BaseController < ActionController::Base
    protect_from_forgery with: :exception
    # No layout specified - host app controllers should set their own layout
    
    class_attribute :crud_model, :permitted_attributes, :column_configurations, :field_configurations
    
    # DSL methods for configuration
    class << self
      # Specify the ActiveRecord model this controller manages
      # @param model_class [Class] The ActiveRecord model class
      def model(model_class)
        self.crud_model = model_class
      end
      
      # Specify permitted parameters for strong params
      # @param attrs [Array<Symbol>] List of permitted attributes
      def permit_params(*attrs)
        self.permitted_attributes = attrs
      end
      
      # Configure columns (for future use)
      # @param config [Hash] Column configuration
      def columns(config = {})
        self.column_configurations = config
      end
      
      # Configure individual field properties and behavior
      # @param field_name [Symbol] The field name
      # @param options [Hash] Configuration options (title, description, readonly, etc.)
      # @yield [FieldConfiguration] Block for DSL-style configuration
      def field(field_name, **options, &block)
        self.field_configurations ||= {}
        
        config = ElaineCrud::FieldConfiguration.new(field_name, **options)
        config.instance_eval(&block) if block_given?
        
        self.field_configurations[field_name.to_sym] = config
      end
    end
    
    # Standard CRUD actions
    def index
      @records = fetch_records
      @model_name = crud_model.name
      @columns = determine_columns
      
      # Handle inline editing mode
      @edit_record_id = params[:edit].to_i if params[:edit].present?
      @editing_record = @edit_record_id ? find_record_by_id(@edit_record_id) : nil
    end
    
    def show
      @record = find_record
      @model_name = crud_model.name
      @columns = determine_columns
      render 'elaine_crud/base/show'
    end
    
    def new
      @record = crud_model.new
      @model_name = crud_model.name
      apply_field_defaults(@record)
      render 'elaine_crud/base/new'
    end
    
    def create
      @record = crud_model.new(record_params)
      
      if @record.save
        redirect_to polymorphic_path(@record), notice: "#{crud_model.name} was successfully created."
      else
        @model_name = crud_model.name
        render 'elaine_crud/base/new', status: :unprocessable_entity
      end
    end
    
    def edit
      @record = find_record
      @model_name = crud_model.name
      render 'elaine_crud/base/edit'
    end
    
    def update
      @record = find_record
      
      if @record.update(record_params)
        # Check if we're updating from inline edit mode
        if params[:from_inline_edit]
          redirect_to url_for(action: :index), notice: "#{crud_model.name} was successfully updated."
        else
          redirect_to polymorphic_path(@record), notice: "#{crud_model.name} was successfully updated."
        end
      else
        # Handle validation errors in inline edit mode
        if params[:from_inline_edit]
          @records = fetch_records
          @model_name = crud_model.name
          @columns = determine_columns
          @edit_record_id = @record.id
          @editing_record = @record
          render 'elaine_crud/base/index', status: :unprocessable_entity
        else
          @model_name = crud_model.name
          render 'elaine_crud/base/edit', status: :unprocessable_entity
        end
      end
    end
    
    def destroy
      @record = find_record
      @record.destroy
      redirect_to polymorphic_path(crud_model), notice: "#{crud_model.name} was successfully deleted."
    end
    
    # Field configuration helper methods (public for access from views/helpers)
    
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
    
    private
    
    # Fetch all records for index view
    # Can be overridden in subclasses for custom filtering/scoping
    def fetch_records
      crud_model.all
    end
    
    # Find a single record by ID
    def find_record
      crud_model.find(params[:id])
    end
    
    # Find a record by a specific ID (used for inline editing)
    def find_record_by_id(id)
      crud_model.find(id)
    rescue ActiveRecord::RecordNotFound
      nil
    end
    
    # Strong parameters
    def record_params
      return {} unless permitted_attributes.present?
      
      params.require(crud_model.name.underscore.to_sym).permit(*permitted_attributes)
    end
    
    # Determine which columns to display
    # TODO: Integrate with field configuration system to respect show_in_index? settings
    def determine_columns
      # Get all potential columns
      all_columns = crud_model.column_names.reject { |col| col == 'id' || col.end_with?('_at') }
      
      # TODO: Filter based on field configurations
      # 1. If field_configurations present, check each field's show_in_index? method
      # 2. Respect any visibility settings in field configurations
      # 3. Maybe allow ordering of columns based on configuration order
      
      # For now, return all non-id/timestamp columns (existing behavior)
      all_columns
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
  end
end