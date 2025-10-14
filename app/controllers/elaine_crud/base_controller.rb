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
    # Include all concerns
    include ElaineCrud::SortingConcern
    include ElaineCrud::SearchAndFiltering
    include ElaineCrud::DSLMethods
    include ElaineCrud::FieldConfigurationMethods
    include ElaineCrud::LayoutCalculation
    include ElaineCrud::RelationshipHandling
    include ElaineCrud::RecordFetching
    include ElaineCrud::ParameterHandling
    include ElaineCrud::ExportHandling

    # Include view helpers so they're available in lambda contexts
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::DateHelper

    protect_from_forgery with: :exception
    # No layout specified - host app controllers should set their own layout

    # Handle record not found errors with custom 404 page
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

    # Standard CRUD actions
    def index
      @records = fetch_records
      @model_name = crud_model.name
      @columns = determine_columns

      # Search/filter metadata
      @search_query = search_query
      @active_filters = filters
      @searchable_columns = determine_searchable_columns
      @filterable_columns = determine_filterable_columns
      @total_count = total_unfiltered_count if search_active?
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
        redirect_to redirect_after_create_path, notice: "#{crud_model.name} was successfully created.", status: :see_other
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

      # Set search/filter metadata for the edit page (which includes search bar)
      @search_query = search_query
      @active_filters = filters
      @searchable_columns = determine_searchable_columns
      @filterable_columns = determine_filterable_columns
      @total_count = total_unfiltered_count if search_active?

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
          # Use bg-white for consistency when returning from edit (alternating colors handled by full page refresh)
          render partial: 'elaine_crud/base/view_row', locals: { record: @record, columns: @columns, row_bg_class: 'bg-white', is_last_record: false }
        else
          redirect_to polymorphic_path(@record), notice: "#{crud_model.name} was successfully updated.", status: :see_other
        end
      else
        # Handle validation errors
        Rails.logger.warn "ElaineCrud: Record update failed with errors: #{@record.errors.full_messages}" if Rails.env.development?

        if turbo_frame_request?
          # Return edit row partial with errors
          render partial: 'elaine_crud/base/edit_row', locals: { record: @record, columns: @columns }, status: :unprocessable_entity
        else
          # Render full edit page with errors - need search/filter metadata
          @records = fetch_records
          @search_query = search_query
          @active_filters = filters
          @searchable_columns = determine_searchable_columns
          @filterable_columns = determine_filterable_columns
          @total_count = total_unfiltered_count if search_active?
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
        redirect_to action: :index
      end
    end

    def destroy
      @record = find_record
      @record.destroy
      redirect_to polymorphic_path(crud_model), notice: "#{crud_model.name} was successfully deleted.", status: :see_other
    end

    private

    # Check if the request is coming from a Turbo Frame
    def turbo_frame_request?
      request.headers['Turbo-Frame'].present?
    end

    # Handle ActiveRecord::RecordNotFound with custom 404 page
    def record_not_found(exception)
      @model_name = crud_model.name
      @model_class = crud_model
      @resource_id = params[:id]
      @exception_message = exception.message

      respond_to do |format|
        format.html { render 'elaine_crud/base/not_found', status: :not_found }
        format.json { render json: { error: 'Record not found' }, status: :not_found }
      end
    end
  end
end
