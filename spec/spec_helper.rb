# frozen_string_literal: true

require 'bundler/setup'
Bundler.setup

ENV['RAILS_ENV'] = 'test'

# Load the dummy app
require File.expand_path('../test/dummy_app/config/environment', __dir__)

require 'rspec/rails'
require 'capybara/rspec'

# Load support files
Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

# Configure Capybara
Capybara.default_driver = :rack_test
Capybara.app = Rails.application

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Use transactions for database cleanup
  config.use_transactional_fixtures = true

  # Reset database before suite
  config.before(:suite) do
    # Load the Rails environment
    Rails.application.load_tasks

    # Reset and seed the database (quietly - suppress seed output during tests)
    ENV['SEED_QUIET'] = 'true'
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:seed'].invoke
    ENV.delete('SEED_QUIET')
  end

  # Start a new transaction for each test
  config.around(:each) do |example|
    ActiveRecord::Base.connection.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
