# frozen_string_literal: true

require_relative 'elaine_crud/version'
require_relative 'elaine_crud/engine'
require_relative 'elaine_crud/field_configuration'

module ElaineCrud
  class Error < StandardError; end
end