# frozen_string_literal: true

begin
  require 'rspec/core/rake_task'

  # Note: Main :spec task is defined in Rakefile to avoid duplication
  # This file only defines namespaced spec tasks for more granular test running

  namespace :spec do
    desc 'Run integration tests'
    RSpec::Core::RakeTask.new(:integration) do |t|
      t.pattern = 'spec/integration/**/*_spec.rb'
      t.rspec_opts = '--format documentation'
    end

    desc 'Run integration tests for a specific controller (e.g., rake spec:controller[libraries])'
    task :controller, [:name] do |t, args|
      controller_name = args[:name]
      sh "bundle exec rspec spec/integration/#{controller_name}_crud_spec.rb --format documentation"
    end
  end

  task default: :spec
rescue LoadError
  # RSpec not available
end
