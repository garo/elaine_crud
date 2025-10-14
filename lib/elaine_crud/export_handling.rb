# frozen_string_literal: true

require 'csv'
require 'caxlsx'

module ElaineCrud
  # Handles data export functionality (CSV, Excel, JSON)
  # Provides export action and format generation methods
  module ExportHandling
    extend ActiveSupport::Concern

    # Export records in CSV, Excel (XLSX), or JSON format
    # Respects current search/filter state and enforces max export limits
    def export
      # Fetch records without pagination for export
      @records = fetch_records_for_export

      # Check record count
      if @records.count > self.class.max_export_records
        redirect_to polymorphic_path(crud_model),
          alert: "Cannot export more than #{self.class.max_export_records} records. Please apply filters to reduce the number of records.",
          status: :see_other
        return
      end

      @columns = determine_columns
      @model_name = crud_model.name

      respond_to do |format|
        format.csv do
          send_data generate_csv(@records, @columns),
            filename: export_filename('csv'),
            type: 'text/csv',
            disposition: 'attachment'
        end

        format.xlsx do
          send_data generate_xlsx(@records, @columns),
            filename: export_filename('xlsx'),
            type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            disposition: 'attachment'
        end

        format.json do
          render json: generate_json(@records, @columns),
            status: :ok
        end
      end
    end

    private

    # Generate CSV content from records
    def generate_csv(records, columns)
      CSV.generate(headers: true) do |csv|
        # Header row
        csv << columns.map { |col| field_title(col.to_sym) }

        # Data rows
        records.each do |record|
          csv << columns.map { |col| export_field_value(record, col.to_sym) }
        end
      end
    end

    # Generate Excel content from records
    def generate_xlsx(records, columns)
      package = Axlsx::Package.new
      workbook = package.workbook

      workbook.add_worksheet(name: @model_name.pluralize) do |sheet|
        # Header row with styling
        header_style = workbook.styles.add_style(b: true, bg_color: 'DDDDDD')
        sheet.add_row columns.map { |col| field_title(col.to_sym) }, style: header_style

        # Data rows
        records.each do |record|
          sheet.add_row columns.map { |col| export_field_value(record, col.to_sym) }
        end
      end

      package.to_stream.read
    end

    # Generate JSON content from records
    def generate_json(records, columns)
      records.map do |record|
        columns.each_with_object({}) do |col, hash|
          hash[col] = export_field_value(record, col.to_sym)
        end
      end
    end

    # Get plain text value for export (without HTML formatting)
    def export_field_value(record, field_name)
      # Check if this is a field configuration
      config = self.class.field_configurations&.dig(field_name)

      # Handle belongs_to relationships (foreign keys)
      column = record.class.columns_hash[field_name.to_s]
      if column&.type == :integer && field_name.to_s.end_with?('_id')
        # This is a foreign key, get the associated record
        association_name = field_name.to_s.gsub(/_id$/, '').to_sym
        begin
          related = record.public_send(association_name)
          if related
            # Try to find display field from config or use :name as default
            reflection = record.class.reflect_on_association(association_name)
            if reflection
              display_field = config&.foreign_key_config&.dig(:display) || :name
              result = related.public_send(display_field) rescue related.to_s
              return result
            end
          end
          return ''
        rescue NoMethodError
          # Not an association, treat as regular field
        end
      end

      # Handle has_many relationships
      if config&.has_many_config
        related_records = record.public_send(field_name)
        return related_records.count.to_s
      end

      # Handle has_one relationships
      if config&.has_one_config
        related = record.public_send(field_name)
        display_field = config.has_one_config.dig(:display) || :name
        return related ? related.public_send(display_field) : ''
      end

      # Handle HABTM relationships
      if config&.habtm_config
        related_records = record.public_send(field_name)
        display_field = config.habtm_config.dig(:display_field) || :name
        return related_records.map { |r| r.public_send(display_field) }.join(', ')
      end

      # Get the actual value
      value = record.public_send(field_name)

      # Handle dates/times
      return value.strftime('%Y-%m-%d %H:%M') if value.is_a?(Time) || value.is_a?(DateTime)
      return value.strftime('%Y-%m-%d') if value.is_a?(Date)

      # Handle booleans
      return value ? 'Yes' : 'No' if [TrueClass, FalseClass].include?(value.class)

      # Handle nil
      return '' if value.nil?

      value.to_s
    end

    # Generate export filename
    def export_filename(extension)
      base = @model_name.pluralize.downcase.gsub(' ', '_')
      suffix = search_active? ? '_filtered' : ''
      "#{base}#{suffix}_#{Date.today.strftime('%Y-%m-%d')}.#{extension}"
    end
  end
end
