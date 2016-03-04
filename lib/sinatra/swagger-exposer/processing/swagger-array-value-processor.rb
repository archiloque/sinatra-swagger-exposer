require_relative '../swagger-parameter-helper'
require_relative '../swagger-invalid-exception'
require_relative 'swagger-base-value-processor'

module Sinatra

  module SwaggerExposer

    module Processing

      # Validate arrays
      class SwaggerArrayValueProcessor < SwaggerBaseValueProcessor

        include Sinatra::SwaggerExposer::SwaggerParameterHelper

        attr_reader :processor_for_values

        # Initialize
        # @param name [String] the name
        # @param required [TrueClass] if the parameter is required
        # @param processor_for_values [Sinatra::SwaggerExposer::Processing::SwaggerBaseValueProcessor] processor for the values
        def initialize(name, required, processor_for_values)
          super(name, required, nil)
          @processor_for_values = processor_for_values
        end

        def useful?
          true
        end

        def validate_value(value)
          if value
            if value.is_a? Array
              value.collect { |i| @processor_for_values.validate_value(i) }
            else
              raise SwaggerInvalidException.new("Value [#{name}] should be an array but is [#{value}]")
            end
          else
            nil
          end
        end

      end
    end
  end
end