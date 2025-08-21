# frozen_string_literal: true

require 'rails/engine'

module ElaineCrud
  class Engine < ::Rails::Engine
    # Non-mountable engine - do not call isolate_namespace
    
    # Make sure our app directories and lib directories are available
    config.autoload_paths << File.expand_path('../../app/controllers', __dir__)
    config.autoload_paths << File.expand_path('../../app/helpers', __dir__)
    config.autoload_paths << File.expand_path('..', __dir__)
    
    # Ensure views are available in the view path
    initializer 'elaine_crud.append_view_paths' do |app|
      ActiveSupport.on_load :action_controller do
        append_view_path File.expand_path('../../app/views', __dir__)
      end
    end
    
    # Include helpers in ActionController::Base so they're available everywhere
    initializer 'elaine_crud.include_helpers' do
      ActiveSupport.on_load :action_controller do
        include ElaineCrud::BaseHelper
      end
    end
  end
end