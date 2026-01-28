# frozen_string_literal: true

require 'rails/engine'
require 'turbo-rails'

module ElaineCrud
  class Engine < ::Rails::Engine
    # Non-mountable engine - do not call isolate_namespace

    # Make sure our app directories and lib directories are available
    config.autoload_paths << File.expand_path('../../app/controllers', __dir__)
    config.autoload_paths << File.expand_path('../../app/helpers', __dir__)
    config.autoload_paths << File.expand_path('..', __dir__)

    # Register XLSX MIME type for Excel exports
    initializer 'elaine_crud.mime_types', before: :load_config_initializers do
      Mime::Type.register 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :xlsx
    end

    # Add vendor/assets to asset paths for precompiled CSS
    initializer 'elaine_crud.assets' do |app|
      app.config.assets.paths << File.expand_path('../../vendor/assets/stylesheets', __dir__) if app.config.respond_to?(:assets)
    end

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
        include ElaineCrud::SearchHelper
      end
    end

    # Extend ActionDispatch::Routing::Mapper to add custom routing DSL
    # This must run before routes are loaded
    initializer 'elaine_crud.add_routing_helper', before: :add_routing_paths do
      require 'elaine_crud/routing'
      ActionDispatch::Routing::Mapper.include ElaineCrud::Routing
    end
  end
end