# frozen_string_literal: true

module ElaineCrud
  # Helper methods for rendering search and filter UI components
  module SearchHelper
    # Render a filter field based on its type
    # @param field_info [Hash] Field information with name, type, and config
    # @return [String] HTML for the filter field
    def render_filter_field(field_info)
      field_name = field_info[:name]
      filter_type = field_info[:type]
      config = field_info[:config]

      case filter_type
      when :select
        render_select_filter(field_name, config)
      when :boolean
        render_boolean_filter(field_name, config)
      when :date_range
        render_date_range_filter(field_name, config)
      when :text
        render_text_filter(field_name, config)
      else
        render_text_filter(field_name, config)
      end
    end

    # Render a select dropdown filter
    # @param field_name [Symbol] Field name
    # @param config [FieldConfiguration, nil] Field configuration
    # @return [String] HTML for select filter
    def render_select_filter(field_name, config)
      content_tag(:div, class: "flex flex-col") do
        label = content_tag(:label, config&.title || field_name.to_s.humanize,
                           class: "text-sm font-medium text-gray-700 mb-1")

        options = get_filter_options(field_name, config)
        select = select_tag "filter[#{field_name}]",
                           options_for_select(options, @active_filters[field_name.to_s]),
                           include_blank: "All",
                           class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"

        label + select
      end
    end

    # Render a boolean filter (Yes/No/All)
    # @param field_name [Symbol] Field name
    # @param config [FieldConfiguration, nil] Field configuration
    # @return [String] HTML for boolean filter
    def render_boolean_filter(field_name, config)
      content_tag(:div, class: "flex flex-col") do
        label = content_tag(:label, config&.title || field_name.to_s.humanize,
                           class: "text-sm font-medium text-gray-700 mb-1")

        select = select_tag "filter[#{field_name}]",
                           options_for_select([["All", ""], ["Yes", "true"], ["No", "false"]],
                                            @active_filters[field_name.to_s]),
                           class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"

        label + select
      end
    end

    # Render a date range filter (from/to inputs)
    # @param field_name [Symbol] Field name
    # @param config [FieldConfiguration, nil] Field configuration
    # @return [String] HTML for date range filter
    def render_date_range_filter(field_name, config)
      content_tag(:div, class: "flex flex-col") do
        label = content_tag(:label, config&.title || field_name.to_s.humanize,
                           class: "text-sm font-medium text-gray-700 mb-1")

        from_field = date_field_tag "filter[#{field_name}_from]",
                                     @active_filters["#{field_name}_from"],
                                     placeholder: "From",
                                     class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"

        to_field = date_field_tag "filter[#{field_name}_to]",
                                   @active_filters["#{field_name}_to"],
                                   placeholder: "To",
                                   class: "block w-full mt-1 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"

        label + from_field + to_field
      end
    end

    # Render a text input filter
    # @param field_name [Symbol] Field name
    # @param config [FieldConfiguration, nil] Field configuration
    # @return [String] HTML for text filter
    def render_text_filter(field_name, config)
      content_tag(:div, class: "flex flex-col") do
        label = content_tag(:label, config&.title || field_name.to_s.humanize,
                           class: "text-sm font-medium text-gray-700 mb-1")

        input = text_field_tag "filter[#{field_name}]",
                              @active_filters[field_name.to_s],
                              placeholder: "Filter by #{(config&.title || field_name.to_s.humanize).downcase}",
                              class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"

        label + input
      end
    end

    # Get filter options for a field
    # @param field_name [Symbol] Field name
    # @param config [FieldConfiguration, nil] Field configuration
    # @return [Array] Array of [display, value] pairs for select options
    def get_filter_options(field_name, config)
      # If field has configured options, use those
      if config&.has_options?
        options = config.options
        # Handle both array and hash formats
        if options.is_a?(Hash)
          options.to_a
        else
          options.map { |opt| [opt, opt] }
        end
      # If it's a foreign key, get options from related model
      elsif config&.has_foreign_key?
        config.foreign_key_options(controller)
      # Otherwise, get distinct values from database
      else
        crud_model.distinct.pluck(field_name).compact.sort.map { |v| [v, v] }
      end
    rescue => e
      Rails.logger.error "ElaineCrud: Error getting filter options for #{field_name}: #{e.message}"
      []
    end
  end
end
