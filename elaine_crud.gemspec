# frozen_string_literal: true

require_relative 'lib/elaine_crud/version'

Gem::Specification.new do |spec|
  spec.name = 'elaine_crud'
  spec.version = ElaineCrud::VERSION
  spec.authors = ['CRUD Generator']
  spec.email = ['crud@example.com']

  spec.summary = 'A Rails engine for generating CRUD UIs for ActiveRecord models'
  spec.description = 'ElaineCrud provides a reusable BaseController and views to quickly generate CRUD interfaces for any ActiveRecord model with minimal configuration.'
  spec.homepage = 'https://github.com/example/elaine_crud'
  spec.license = 'MIT'
  
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/example/elaine_crud'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z 2>/dev/null`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end

  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'rails', '>= 6.0'

  # Development dependencies
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-rails', '~> 6.0'
  spec.add_development_dependency 'capybara', '~> 3.0'
  spec.add_development_dependency 'sqlite3', '~> 2.1'
  spec.add_development_dependency 'puma', '~> 6.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end