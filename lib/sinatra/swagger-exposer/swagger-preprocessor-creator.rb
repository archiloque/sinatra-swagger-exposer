require_relative 'swagger-parameter-helper'

require_relative 'processing/swagger-array-value-preprocessor'
require_relative 'processing/swagger-preprocessor-dispatcher'
require_relative 'processing/swagger-primitive-value-preprocessor'
require_relative 'processing/swagger-request-preprocessor'
require_relative 'processing/swagger-type-value-preprocessor'

module Sinatra

  module SwaggerExposer

    # Create processor from configuration
    class SwaggerPreprocessorCreator

      include Sinatra::SwaggerExposer::SwaggerParameterHelper

      # Initialize
      # @param types [Sinatra::SwaggerExposer::SwaggerTypes]
      def initialize(types)
        @types = types
      end

      # Create an endpoint processor
      # @param swagger_endpoint [Sinatra::SwaggerExposer::Configuration::SwaggerEndpoint] the endpoint
      # @return [Sinatra::SwaggerExposer::Processing::SwaggerRequestPreprocessor]
      def create_endpoint_processor(swagger_endpoint)
        request_preprocessor = Sinatra::SwaggerExposer::Processing::SwaggerRequestPreprocessor.new
        swagger_endpoint.parameters.each do |parameter|
          preprocessor = create_value_preprocessor(parameter)
          dispatcher = Sinatra::SwaggerExposer::Processing::SwaggerPreprocessorDispatcher.new(parameter.how_to_pass, preprocessor)
          if dispatcher.useful?
            request_preprocessor.add_dispatcher(dispatcher)
          end
        end
        request_preprocessor
      end

      private

      # Create a parameter preprocessor for a parameter
      # @param parameter [Sinatra::SwaggerExposer::Configuration::SwaggerEndpointParameter]
      def create_value_preprocessor(parameter)
        type_name = parameter.type
        if type_name == TYPE_ARRAY
          if PRIMITIVE_TYPES.include? parameter.items
            preprocessor_for_values = Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValuePreprocessor.new(
              parameter.name,
              false,
              parameter.items,
              parameter.default,
              parameter.params
            )
          else
            preprocessor_for_values = create_preprocessor_for_type(parameter.name, parameter.items, false)
          end
          Sinatra::SwaggerExposer::Processing::SwaggerArrayValuePreprocessor.new(parameter.name, parameter.required, preprocessor_for_values)
        elsif PRIMITIVE_TYPES.include? type_name
          Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValuePreprocessor.new(
            parameter.name,
            parameter.required,
            type_name,
            parameter.default,
            parameter.params
          )
        else
          create_preprocessor_for_type(parameter.name, parameter.type, parameter.required)
        end
      end

      # Create a type parameter preprocessor for a type parameter
      # @param parameter_name [String] the parameter name
      # @param parameter_type [String] the parameter type
      # @param parameter_required [TrueClass] if the parameter is required
      # @return [Sinatra::SwaggerExposer::Processing::SwaggerTypeValuePreprocessor]
      def create_preprocessor_for_type(parameter_name, parameter_type, parameter_required)
        attributes_preprocessors = create_attributes_preprocessors_for_type(parameter_type)
        Sinatra::SwaggerExposer::Processing::SwaggerTypeValuePreprocessor.new(
          parameter_name,
          parameter_required,
          attributes_preprocessors
        )
      end

      # Get attributes preprocessor for a type
      # @param type_name [String] the type name
      # @return [Array[Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValuePreprocessor]]
      def create_attributes_preprocessors_for_type(type_name)
        type = @types[type_name]
        attributes_preprocessors = []
        type.properties.each_pair do |property_name, property|
          attributes_preprocessors <<
            create_preprocessor_for_property(
              property_name,
              property,
              type.required.include?(property.name)
            )
        end
        if type.extends
          attributes_preprocessors = attributes_preprocessors + create_attributes_preprocessors_for_type(type.extends)
        end
        attributes_preprocessors
      end

      # Create a processor for a type property
      # @param type_property [Sinatra::SwaggerExposer::Configuration::SwaggerTypeProperty]
      def create_preprocessor_for_property(name, type_property, required)
        property_type = type_property.type
        if property_type == TYPE_ARRAY
          if PRIMITIVE_TYPES.include? type_property.items
            preprocessor_for_values = Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValuePreprocessor.new(
              name,
              false,
              type_property.items,
              type_property.properties[:default],
              type_property.properties
            )
          else
            preprocessor_for_values = create_preprocessor_for_type(name, type_property.items, false)
          end
          Sinatra::SwaggerExposer::Processing::SwaggerArrayValuePreprocessor.new(name, required, preprocessor_for_values)
        elsif PRIMITIVE_TYPES.include? property_type
          Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValuePreprocessor.new(
            name,
            required,
            property_type,
            type_property.properties[:default],
            type_property.properties
          )
        else
          create_preprocessor_for_type(name, property_type, required)
        end
      end

    end

  end
end
