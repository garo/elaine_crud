# frozen_string_literal: true

module ElaineCrud
  # Extends ActionDispatch::Routing::Mapper to automatically add export routes
  # to all resources that inherit from ElaineCrud::BaseController
  module Routing
    # Override the resources method to automatically add export action
    # for controllers inheriting from ElaineCrud::BaseController
    def resources(*args, &block)
      super(*args) do
        # Check if the controller uses ElaineCrud
        resource_name = args.first
        controller_name = "#{resource_name.to_s.camelize}Controller"

        begin
          controller_class = controller_name.constantize
          # Add ElaineCrud routes if controller inherits from ElaineCrud::BaseController
          if controller_class < ElaineCrud::BaseController
            collection do
              get :export      # For CSV/Excel/JSON export
              get :new_modal   # For nested record creation in modal
            end
          end
        rescue NameError
          # Controller doesn't exist yet or doesn't use ElaineCrud - skip
        end

        # Allow custom block to be evaluated
        instance_eval(&block) if block_given?
      end
    end
  end
end
