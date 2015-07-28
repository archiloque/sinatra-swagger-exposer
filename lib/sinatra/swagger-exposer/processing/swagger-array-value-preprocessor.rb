require_relative '../swagger-parameter-helper'
require_relative '../swagger-invalid-exception'
require_relative 'swagger-base-value-preprocessor'

module Sinatra

  module SwaggerExposer

    module Processing

      # Validate arrays parameters
      class SwaggerArrayValuePreprocessor < SwaggerBaseValuePreprocessor

        include Sinatra::SwaggerExposer::SwaggerParameterHelper

        attr_reader :preprocessor_for_values

        # Initialize
        # @param name [String] the name
        # @param required [TrueClass] if the parameter is required
        # @param preprocessor_for_values [Sinatra::SwaggerExposer::Processing::SwaggerBaseValuePreprocessor] processor for the values
        def initialize(name, required, preprocessor_for_values)
          super(name, required)
          @preprocessor_for_values = preprocessor_for_values
        end

        def useful?
          true
        end

        def validate_param_value(value)
          if value
            if value.is_a? Array
              value.collect { |i| @preprocessor_for_values.validate_param_value(i) }
            else
              raise SwaggerInvalidException.new("Parameter [#{name}] should be an array but is [#{value}]")
            end
          else
            nil
          end
        end

      end
    end
  end
end