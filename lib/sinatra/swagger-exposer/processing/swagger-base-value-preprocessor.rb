require_relative '../swagger-parameter-helper'
require_relative '../swagger-invalid-exception'

module Sinatra

  module SwaggerExposer

    module Processing

      # Base class for value preprocessor
      class SwaggerBaseValuePreprocessor

        attr_reader :name, :required

        include Sinatra::SwaggerExposer::SwaggerParameterHelper

        # Initialize
        # @param name [String] the name
        # @param required [TrueClass] if the parameter is required
        # @param default [Object] the default value
        def initialize(name, required, default = nil)
          @name = name.to_s
          @required = required
          @default = default
        end

        def useful?
          @required || (!@default.nil?)
        end

        def process(params)
          unless params.is_a? Hash
            raise SwaggerInvalidException.new("Parameter [#{@name}] should be an object but is a [#{params.class}]")
          end
          if params.key?(@name)
            params[@name] = validate_param_value(params[@name])
          elsif @required
            raise SwaggerInvalidException.new("Mandatory parameter [#{@name}] is missing")
          elsif @default
            params[@name] = @default
          end
          params
        end

      end
    end
  end
end