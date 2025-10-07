# frozen_string_literal: true

module ElaineCrud
  # Methods for handling strong parameters
  # Processes form submissions and enforces permitted attributes
  module ParameterHandling
    extend ActiveSupport::Concern

    private

    # Strong parameters
    # @return [ActionController::Parameters] Filtered parameters
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
  end
end
