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

# Register Chrome drivers for JS tests (if selenium-webdriver is available)
begin
  require 'selenium-webdriver'

  # Default to headless for CI/automated runs
  Capybara.javascript_driver = :selenium_headless_chrome

  # Headless Chrome (invisible, fast)
  Capybara.register_driver :selenium_headless_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  # Visible Chrome (for debugging - watch the browser in action)
  # Use with: SELENIUM_VISIBLE=true bundle exec rspec
  Capybara.register_driver :selenium_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    # Optionally start maximized to see everything clearly
    options.add_argument('--start-maximized')

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  # Switch to visible browser if SELENIUM_VISIBLE environment variable is set
  if ENV['SELENIUM_VISIBLE']
    Capybara.javascript_driver = :selenium_chrome
    puts "Running tests in VISIBLE browser mode - you can watch the tests execute!"
  end
rescue LoadError
  # Selenium not available - JS tests will be skipped
  puts "Warning: selenium-webdriver gem not found. JavaScript tests will be skipped."
  puts "To run JS tests, add selenium-webdriver to your Gemfile and run 'bundle install'"
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Skip JS tests if Selenium is not available
  config.filter_run_excluding js: true unless defined?(Selenium)

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
