# frozen_string_literal: true

require 'kaminari'

require_relative 'elaine_crud/version'
require_relative 'elaine_crud/engine'
require_relative 'elaine_crud/field_configuration'
require_relative 'elaine_crud/sorting_concern'
require_relative 'elaine_crud/search_and_filtering'

# Controller concerns
require_relative 'elaine_crud/dsl_methods'
require_relative 'elaine_crud/field_configuration_methods'
require_relative 'elaine_crud/layout_calculation'
require_relative 'elaine_crud/relationship_handling'
require_relative 'elaine_crud/record_fetching'
require_relative 'elaine_crud/parameter_handling'

module ElaineCrud
  class Error < StandardError; end
end