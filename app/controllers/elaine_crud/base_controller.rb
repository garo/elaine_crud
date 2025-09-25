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
    
    # Include view helpers so they're available in lambda contexts
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::DateHelper
    
    protect_from_forgery with: :exception
    # No layout specified - host app controllers should set their own layout
    
    class_attribute :crud_model, :permitted_attributes, :column_configurations, :field_configurations, :default_sort_column, :default_sort_direction, :disable_turbo_frames
    
    # DSL methods for configuration
    class << self
      # Specify the ActiveRecord model this controller manages
      # @param model_class [Class] The ActiveRecord model class
      def model(model_class)
        self.crud_model = model_class
        # Auto-configure foreign key fields after setting the model
        auto_configure_foreign_keys if model_class
        # Auto-configure has_many relationships
        auto_configure_has_many_relationships if model_class
        # Re-run permit_params to include foreign keys if it was called before model was set
        refresh_permitted_attributes
      end
      
      # Specify permitted parameters for strong params
      # @param attrs [Array<Symbol>] List of permitted attributes
      def permit_params(*attrs)
        # Store manual attributes for later refresh if needed
        @manual_permitted_attributes = attrs
        
        # Auto-include foreign keys from belongs_to relationships
        foreign_keys = get_foreign_keys_from_model
        final_attrs = (attrs + foreign_keys).uniq
        self.permitted_attributes = final_attrs
        
        # Debug logging for development
        if Rails.env.development?
          Rails.logger.info "ElaineCrud: Setting permitted attributes to: #{final_attrs.inspect}"
          Rails.logger.info "ElaineCrud: Manual attributes: #{attrs.inspect}"
          Rails.logger.info "ElaineCrud: Auto-detected foreign keys: #{foreign_keys.inspect}"
        end
      end
      
      # Get foreign keys from belongs_to relationships
      # @return [Array<Symbol>] List of foreign key attributes
      def get_foreign_keys_from_model
        return [] unless crud_model
        
        foreign_keys = []
        crud_model.reflections.each do |name, reflection|
          next unless reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection)
          foreign_keys << reflection.foreign_key.to_sym
        end
        
        foreign_keys
      end
      
      # Store the manually specified attributes for later use
      attr_accessor :manual_permitted_attributes
      
      # Refresh permitted attributes (called when model is set after permit_params)
      def refresh_permitted_attributes
        return unless @manual_permitted_attributes
        
        foreign_keys = get_foreign_keys_from_model
        final_attrs = (@manual_permitted_attributes + foreign_keys).uniq
        self.permitted_attributes = final_attrs
        
        if Rails.env.development?
          Rails.logger.info "ElaineCrud: Refreshed permitted attributes to: #{final_attrs.inspect}"
        end
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
      
      # Disable Turbo Frame functionality for this controller
      # When disabled, edit links will navigate to full page instead of inline editing
      def disable_turbo
        self.disable_turbo_frames = true
      end
      
      # Automatically configure foreign key fields based on belongs_to relationships
      # This method is called automatically when the model is set
      def auto_configure_foreign_keys
        return unless crud_model
        
        # Initialize field configurations if not already done
        self.field_configurations ||= {}
        
        # Find all belongs_to relationships
        crud_model.reflections.each do |name, reflection|
          next unless reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection)
          
          foreign_key = reflection.foreign_key.to_sym
          
          # Skip if already manually configured
          next if field_configurations[foreign_key]
          
          # Auto-configure this foreign key field
          auto_configure_belongs_to_field(reflection)
        end
      end
      
      private
      
      # Auto-configure a single belongs_to foreign key field
      # @param reflection [ActiveRecord::Reflection::BelongsToReflection] The belongs_to reflection
      def auto_configure_belongs_to_field(reflection)
        foreign_key = reflection.foreign_key.to_sym
        related_model = reflection.klass
        
        # Try to determine the display field for the related model
        display_field = determine_display_field_for_model(related_model)
        
        # Create field configuration
        config = ElaineCrud::FieldConfiguration.new(
          foreign_key,
          title: reflection.name.to_s.humanize,
          foreign_key: {
            model: related_model,
            display: display_field,
            null_option: "Select #{reflection.name.to_s.humanize}"
          }
        )
        
        self.field_configurations[foreign_key] = config
      end
      
      # Auto-configure has_many relationship display
      def auto_configure_has_many_relationships
        return unless crud_model
        
        self.field_configurations ||= {}
        
        # Find all has_many relationships
        crud_model.reflections.each do |name, reflection|
          next unless reflection.is_a?(ActiveRecord::Reflection::HasManyReflection)
          
          # Skip if already manually configured
          field_name = name.to_sym
          next if field_configurations[field_name]
          
          # Auto-configure this has_many field
          auto_configure_has_many_field(reflection)
        end
      end
      
      # Auto-configure a single has_many relationship field
      def auto_configure_has_many_field(reflection)
        field_name = reflection.name.to_sym
        related_model = reflection.klass
        
        # Determine display field for related records
        display_field = determine_display_field_for_model(related_model)
        
        # Create field configuration for has_many
        config = ElaineCrud::FieldConfiguration.new(
          field_name,
          title: reflection.name.to_s.humanize,
          has_many: {
            model: related_model,
            display: display_field,
            foreign_key: reflection.foreign_key,
            show_count: true,
            max_preview_items: 3
          }
        )
        
        self.field_configurations[field_name] = config
      end
      
      # Configure has_many relationship display and behavior
      def has_many_relation(relation_name, **options, &block)
        self.field_configurations ||= {}
        
        config = ElaineCrud::FieldConfiguration.new(relation_name, **options)
        config.instance_eval(&block) if block_given?
        
        # Set has_many specific configuration - extract only the has_many hash
        if options[:has_many]
          config.has_many(**options[:has_many])
        end
        
        self.field_configurations[relation_name.to_sym] = config
      end
      
      # Determine the best display field for a model (class method)
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
      
      # Pre-populate with parent relationship if filtering by parent
      populate_parent_relationships(@record)
      
      apply_field_defaults(@record)
      render 'elaine_crud/base/new'
    end
    
    def create
      @record = crud_model.new(record_params)
      
      # Ensure parent relationship is maintained
      populate_parent_relationships(@record) if @record.errors.any?
      
      if @record.save
        # Redirect back to filtered view if came from parent context
        redirect_to redirect_after_create_path, notice: "#{crud_model.name} was successfully created."
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
      
      # If Turbo is disabled, always render the full edit page
      if turbo_disabled?
        render 'elaine_crud/base/edit'
      elsif turbo_frame_request?
        # For Turbo Frame requests, return just the edit row partial
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
      
      update_params = record_params
      
      # Debug logging for development
      if Rails.env.development?
        Rails.logger.info "ElaineCrud: Attempting to update with params: #{update_params.inspect}"
        Rails.logger.info "ElaineCrud: Record before update: #{@record.attributes.inspect}"
      end
      
      if @record.update(update_params)
        Rails.logger.info "ElaineCrud: Record updated successfully: #{@record.attributes.inspect}" if Rails.env.development?
        
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
        Rails.logger.warn "ElaineCrud: Record update failed with errors: #{@record.errors.full_messages}" if Rails.env.development?
        
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
    

    
    private
    
    # Check if the request is coming from a Turbo Frame
    def turbo_frame_request?
      request.headers['Turbo-Frame'].present?
    end
    
    # Fetch all records for index view
    # Can be overridden in subclasses for custom filtering/scoping
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
      
      model_param_key = crud_model.name.underscore.to_sym
      
      # Debug logging for development
      if Rails.env.development?
        Rails.logger.info "ElaineCrud: Looking for params under key '#{model_param_key}'"
        Rails.logger.info "ElaineCrud: Available param keys: #{params.keys.inspect}"
        Rails.logger.info "ElaineCrud: Permitted attributes: #{permitted_attributes.inspect}"
        Rails.logger.info "ElaineCrud: Model name: #{crud_model.name}"
        Rails.logger.info "ElaineCrud: Model underscore: #{crud_model.name.underscore}"
        
        # Show the actual parameter structure
        params.keys.each do |key|
          if params[key].is_a?(ActionController::Parameters) || params[key].is_a?(Hash)
            Rails.logger.info "ElaineCrud: params[#{key}] = #{params[key].inspect}"
          end
        end
      end
      
      if params[model_param_key].present?
        filtered_params = params.require(model_param_key).permit(*permitted_attributes)
        Rails.logger.info "ElaineCrud: Successfully filtered params: #{filtered_params.inspect}" if Rails.env.development?
        filtered_params
      else
        Rails.logger.warn "ElaineCrud: No parameters found for model '#{model_param_key}'" if Rails.env.development?
        Rails.logger.info "ElaineCrud: Available top-level param structure:" if Rails.env.development?
        params.each do |key, value|
          Rails.logger.info "ElaineCrud:   #{key} => #{value.class} (#{value.is_a?(Hash) || value.is_a?(ActionController::Parameters) ? value.keys.inspect : value.inspect})"
        end
        {}
      end
    end
    
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
    
    # Determine which columns to display
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
    
    # Apply default values to a new record based on field configurations
    # @param record [ActiveRecord::Base] The record to apply defaults to
    def apply_field_defaults(record)
      # TODO: Implement default value application
      # Should iterate through field configurations and apply default_value if present
      # Should handle both static values and proc/lambda callbacks
      # Should only apply to new records (record.new_record?)
      return record # Placeholder
    end
    
    # Apply filtering based on parent relationship parameters
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
    def valid_parent_filter?(field_name)
      crud_model.column_names.include?(field_name.to_s) &&
      field_name.to_s.end_with?('_id')
    end

    # Set context for UI display
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
    def find_reflection_by_foreign_key(foreign_key)
      crud_model.reflections.values.find do |reflection|
        reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection) &&
        reflection.foreign_key.to_sym == foreign_key.to_sym
      end
    end

    # Get list of associations to include for avoiding N+1 queries  
    def get_all_relationship_includes
      return [] unless crud_model
      
      includes = []
      
      # Include belongs_to relationships (existing logic)
      includes += get_belongs_to_includes
      
      # Include has_many relationships that are displayed
      includes += get_has_many_includes
      
      includes.uniq
    end

    # Get has_many relationships that need to be included
    def get_has_many_includes
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

    # Populate parent relationships from URL parameters
    def populate_parent_relationships(record)
      detect_parent_filters.each do |foreign_key, parent_id|
        if valid_parent_filter?(foreign_key) && record.public_send(foreign_key).blank?
          record.public_send("#{foreign_key}=", parent_id)
        end
      end
    end

    # Determine redirect path after create based on context
    def redirect_after_create_path
      if @parent_context
        # Redirect back to filtered index view
        url_for(action: :index, @parent_context[:foreign_key] => @parent_context[:record].id)
      else
        # Standard redirect to show page
        polymorphic_path(@record)
      end
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