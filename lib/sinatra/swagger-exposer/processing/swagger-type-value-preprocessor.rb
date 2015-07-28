require_relative 'swagger-base-value-preprocessor'

module Sinatra

  module SwaggerExposer

    module Processing

      # A preprocessor for a type parameter
      class SwaggerTypeValuePreprocessor < SwaggerBaseValuePreprocessor

        attr_reader :attributes_preprocessors

        # Initialize
        # @param name [String] the name
        # @param required [TrueClass] if the parameter is required
        # @param attributes_preprocessors [Array[Sinatra::SwaggerExposer::Processing::SwaggerBaseValuePreprocessor]] the attributes preprocessors
        def initialize(name, required, attributes_preprocessors)
          super(name, required)
          @attributes_preprocessors = attributes_preprocessors
        end

        def useful?
          super || (!(@attributes_preprocessors.empty?))
        end

        def validate_param_value(value)
          @attributes_preprocessors.each do |attribute_preprocessor|
            attribute_preprocessor.process(value)
          end
          value
        end

      end
    end
  end
end