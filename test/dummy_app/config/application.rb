require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

# Require the elaine_crud gem
require "elaine_crud"

module DummyApp
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # Don't generate system test files
    config.generators.system_tests = nil

    # Set the root
    config.root = File.expand_path('../..', __FILE__)

    # Eager load paths
    config.eager_load_paths << File.expand_path('../app/models', __dir__)
    config.eager_load_paths << File.expand_path('../app/controllers', __dir__)

    # Secret key base for sessions
    config.secret_key_base = 'dummy_secret_key_base_for_testing_purposes_only'
  end
end
