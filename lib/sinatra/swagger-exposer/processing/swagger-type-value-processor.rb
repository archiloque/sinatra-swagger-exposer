require_relative 'swagger-base-value-processor'

module Sinatra

  module SwaggerExposer

    module Processing

      # A processor for a type parameter
      class SwaggerTypeValueProcessor < SwaggerBaseValueProcessor

        attr_reader :attributes_processors

        # Initialize
        # @param name [String] the name
        # @param required [TrueClass] if the parameter is required
        # @param attributes_processors [Array<Sinatra::SwaggerExposer::Processing::SwaggerBaseValueProcessor>] the attributes processors
        def initialize(name, required, attributes_processors)
          super(name, required, nil)
          @attributes_processors = attributes_processors
        end

        def useful?
          super || (!(@attributes_processors.empty?))
        end

        def validate_value(value)
          @attributes_processors.each do |attribute_processor|
            attribute_processor.process(value)
          end
          value
        end

      end
    end
  end
end