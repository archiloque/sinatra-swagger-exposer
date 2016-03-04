require_relative '../swagger-parameter-helper'
require_relative '../swagger-invalid-exception'

module Sinatra

  module SwaggerExposer

    module Processing

      # Base class for value processor
      class SwaggerBaseValueProcessor

        attr_reader :name, :required

        include Sinatra::SwaggerExposer::SwaggerParameterHelper

        # Initialize
        # @param name [String] the name
        # @param required [TrueClass] if the parameter is required
        # @param default [Object] the default value
        def initialize(name, required, default)
          @name = name.to_s
          @required = required
          @default = default
        end

        # Test if the processor is useful
        # @return [TrueClass]
        def useful?
          @required || (!@default.nil?)
        end

        def process(params)
          unless params.is_a? Hash
            raise SwaggerInvalidException.new("Value [#{@name}] should be an object but is a [#{params.class}]")
          end
          if params.key?(@name) && (!params[@name].nil?)
            params[@name] = validate_value(params[@name])
          elsif @required
            raise SwaggerInvalidException.new("Mandatory value [#{@name}] is missing")
          elsif @default
            params[@name] = @default
          end
          params
        end

      end
    end
  end
end