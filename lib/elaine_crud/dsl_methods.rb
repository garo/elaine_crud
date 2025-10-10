# frozen_string_literal: true

module ElaineCrud
  # DSL methods for controller configuration
  # Provides class-level methods for configuring CRUD behavior
  module DSLMethods
    extend ActiveSupport::Concern

    included do
      class_attribute :crud_model, :permitted_attributes, :column_configurations,
                      :field_configurations, :default_sort_column, :default_sort_direction,
                      :disable_turbo_frames, :show_view_action_button

      # Default: View button is disabled
      self.show_view_action_button = false
    end

    class_methods do
      # Specify the ActiveRecord model this controller manages
      # @param model_class [Class] The ActiveRecord model class
      def model(model_class)
        self.crud_model = model_class
        # Auto-configure foreign key fields after setting the model
        auto_configure_foreign_keys if model_class
        # Auto-configure has_many relationships
        auto_configure_has_many_relationships if model_class
        # Auto-configure has_one relationships
        auto_configure_has_one_relationships if model_class
        # Auto-configure has_and_belongs_to_many relationships
        auto_configure_habtm_relationships if model_class
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

      # Get foreign keys from belongs_to relationships and HABTM singular_ids
      # @return [Array<Symbol>] List of foreign key attributes
      def get_foreign_keys_from_model
        return [] unless crud_model

        foreign_keys = []
        crud_model.reflections.each do |name, reflection|
          case reflection
          when ActiveRecord::Reflection::BelongsToReflection
            foreign_keys << reflection.foreign_key.to_sym
          when ActiveRecord::Reflection::HasAndBelongsToManyReflection
            # Add the singular_ids parameter for HABTM (e.g., tag_ids for tags)
            foreign_keys << { "#{name.to_s.singularize}_ids".to_sym => [] }
          end
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

      # Enable the "View" button in the actions column for index/list views
      # @param enabled [Boolean] Whether to show the View button (default: true)
      def show_view_button(enabled = true)
        self.show_view_action_button = enabled
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

      # Auto-configure has_one relationship display
      def auto_configure_has_one_relationships
        return unless crud_model

        self.field_configurations ||= {}

        # Find all has_one relationships
        crud_model.reflections.each do |name, reflection|
          next unless reflection.is_a?(ActiveRecord::Reflection::HasOneReflection)

          # Skip if already manually configured
          field_name = name.to_sym
          next if field_configurations[field_name]

          # Auto-configure this has_one field
          auto_configure_has_one_field(reflection)
        end
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

      # Auto-configure a single has_one relationship field
      def auto_configure_has_one_field(reflection)
        field_name = reflection.name.to_sym
        related_model = reflection.klass

        # Determine display field for related record
        display_field = determine_display_field_for_model(related_model)

        # Create field configuration for has_one
        config = ElaineCrud::FieldConfiguration.new(
          field_name,
          title: reflection.name.to_s.humanize,
          has_one: {
            model: related_model,
            display: display_field,
            foreign_key: reflection.foreign_key
          }
        )

        self.field_configurations[field_name] = config
      end

      # Auto-configure has_and_belongs_to_many relationship display
      def auto_configure_habtm_relationships
        return unless crud_model

        self.field_configurations ||= {}

        # Find all HABTM relationships
        crud_model.reflections.each do |name, reflection|
          next unless reflection.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)

          # Skip if already manually configured
          field_name = name.to_sym
          next if field_configurations[field_name]

          # Auto-configure this HABTM field
          auto_configure_habtm_field(reflection)
        end
      end

      # Auto-configure a single HABTM relationship field - minimal implementation
      # Applications should use display_as for custom rendering
      def auto_configure_habtm_field(reflection)
        field_name = reflection.name.to_sym
        related_model = reflection.klass

        # Create minimal field configuration for HABTM
        config = ElaineCrud::FieldConfiguration.new(
          field_name,
          title: reflection.name.to_s.humanize,
          habtm: {
            model: related_model,
            display_field: determine_display_field_for_model(related_model)
          }
        )

        self.field_configurations[field_name] = config
      end
    end
  end
end
