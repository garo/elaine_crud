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
    include ElaineCrud::SortingConcern
    
    protect_from_forgery with: :exception
    # No layout specified - host app controllers should set their own layout
    
    class_attribute :crud_model, :permitted_attributes, :column_configurations, :field_configurations, :default_sort_column, :default_sort_direction
    
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
      
      # Configure default sorting
      # @param column [Symbol] The column to sort by (default: :id)
      # @param direction [Symbol] The sort direction :asc or :desc (default: :asc)
      def default_sort(column: :id, direction: :asc)
        self.default_sort_column = column
        self.default_sort_direction = direction
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
      @records = fetch_records  # Fetch all records for the edit page
      @model_name = crud_model.name
      @columns = determine_columns
      
      # For Turbo Frame requests, return just the edit row partial
      if turbo_frame_request?
        render partial: 'elaine_crud/base/edit_row', locals: { record: @record, columns: @columns }
      else
        # For direct access, render the full edit page showing all records with this one in edit mode
        render 'elaine_crud/base/edit'
      end
    end
    
    def update
      @record = find_record
      @model_name = crud_model.name
      @columns = determine_columns
      
      if @record.update(record_params)
        # For Turbo Frame requests, return the view row partial
        if turbo_frame_request?
          header_layout = calculate_layout_header(@columns.map(&:to_sym))
          render partial: 'elaine_crud/base/view_row', locals: { record: @record, columns: @columns, header_layout: header_layout }
        elsif params[:from_inline_edit]
          # Legacy inline edit mode (will be deprecated)
          redirect_to url_for(action: :index), notice: "#{crud_model.name} was successfully updated."
        else
          redirect_to polymorphic_path(@record), notice: "#{crud_model.name} was successfully updated."
        end
      else
        # Handle validation errors
        if turbo_frame_request?
          # Return edit row partial with errors
          render partial: 'elaine_crud/base/edit_row', locals: { record: @record, columns: @columns }, status: :unprocessable_entity
        elsif params[:from_inline_edit]
          # Legacy inline edit mode (will be deprecated)
          @records = fetch_records
          @edit_record_id = @record.id
          @editing_record = @record
          render 'elaine_crud/base/index', status: :unprocessable_entity
        else
          render 'elaine_crud/base/edit', status: :unprocessable_entity
        end
      end
    end
    
    def cancel_edit
      @record = find_record
      @model_name = crud_model.name
      @columns = determine_columns
      
      # For Turbo Frame requests, return just the view row partial
      if turbo_frame_request?
        header_layout = calculate_layout_header(@columns.map(&:to_sym))
        render partial: 'elaine_crud/base/view_row', locals: { record: @record, columns: @columns, header_layout: header_layout }
      else
        # For direct access, redirect to index
        redirect_to url_for(action: :index)
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
    
    # Calculate layout structure for a specific record
    # @param content [ActiveRecord::Base] The record being displayed
    # @param fields [Array<Symbol>] Array of field names to include in layout
    # @return [Array<Array<Hash>>] Nested array where first dimension is rows, second is columns
    #   Each column hash can contain: field_name, colspan, rowspan, and future properties
    def calculate_layout(content, fields)
      # Default implementation: single row with all fields, each taking 1 column and 1 row
      row = fields.map do |field_name|
        {
          field_name: field_name,
          colspan: 1,
          rowspan: 1
        }
      end
      
      [row] # Return single row
    end
    
    # Calculate layout header structure defining column sizes and titles
    # @param fields [Array<Symbol>] Array of field names to include in layout
    # @return [Array<Hash>] Array of header config objects with width, field_name, and/or title
    #   Each object can contain:
    #   - width: CSS width (required, e.g., "25%")  
    #   - field_name: Symbol of field to display and enable sorting (optional)
    #   - title: Custom column title, overrides field title (optional)
    def calculate_layout_header(fields)
      # Default implementation: equal distribution with field names for sorting
      fields << "ROW-ACTIONS"
      field_count = fields.length
      percentage = (100.0 / field_count).round(1)
      
      fields.map do |field_name|
        {
          width: "#{percentage}%",
          field_name: field_name
        }
      end
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
    
    # Check if the request is coming from a Turbo Frame
    def turbo_frame_request?
      request.headers['Turbo-Frame'].present?
    end
    
    # Fetch all records for index view
    # Can be overridden in subclasses for custom filtering/scoping
    def fetch_records
      records = crud_model.all
      apply_sorting(records)
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
    def determine_columns
      # Get all potential columns (including id now)
      all_columns = crud_model.column_names
      
      # Filter columns based on field configurations and new visibility rules
      all_columns.select do |col|
        field_config = field_config_for(col.to_sym)
        
        if field_config&.visible == false
          # Explicitly hidden via field configuration
          false
        elsif field_config&.visible == true
          # Explicitly shown via field configuration (even if it ends with '_at')
          true
        else
          # Default behavior: hide columns ending with '_at', show everything else
          !col.end_with?('_at')
        end
      end
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