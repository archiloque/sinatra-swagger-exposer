require_relative 'swagger-parameter-helper'

require_relative 'processing/swagger-array-value-processor'
require_relative 'processing/swagger-file-processor-dispatcher'
require_relative 'processing/swagger-processor-dispatcher'
require_relative 'processing/swagger-primitive-value-processor'
require_relative 'processing/swagger-request-processor'
require_relative 'processing/swagger-response-processor'
require_relative 'processing/swagger-type-value-processor'

module Sinatra

  module SwaggerExposer

    # Create processor from configuration
    class SwaggerProcessorCreator

      include Sinatra::SwaggerExposer::SwaggerParameterHelper

      # Initialize
      # @param types [Sinatra::SwaggerExposer::SwaggerTypes]
      def initialize(types)
        @types = types
      end

      # Create an endpoint processor
      # @param swagger_endpoint [Sinatra::SwaggerExposer::Configuration::SwaggerEndpoint] the endpoint
      # @return [Sinatra::SwaggerExposer::Processing::SwaggerRequestProcessor]
      def create_request_processor(swagger_endpoint)
        request_processor = Sinatra::SwaggerExposer::Processing::SwaggerRequestProcessor.new(swagger_endpoint.produces)

        swagger_endpoint.parameters.each do |parameter|
          if TYPE_FILE == parameter.type
            dispatcher = Sinatra::SwaggerExposer::Processing::SwaggerFileProcessorDispatcher.new(
              parameter.name,
              parameter.required
            )
          else
            processor = create_parameter_value_processor(parameter)
            dispatcher = Sinatra::SwaggerExposer::Processing::SwaggerProcessorDispatcher.new(
              parameter.how_to_pass,
              processor
            )
          end
          if dispatcher.useful?
            request_processor.add_dispatcher(dispatcher)
          end
        end

        swagger_endpoint.responses.each_pair do |code, endpoint_response|
          response_value_processor = create_response_value_processor(endpoint_response)
          response_processor = Sinatra::SwaggerExposer::Processing::SwaggerResponseProcessor.new(
            endpoint_response,
            response_value_processor
          )
          request_processor.add_response_processor(
            code,
            response_processor.useful? ? response_processor : nil
          )
        end

        request_processor
      end

      private

      # Create a response processor
      # @param endpoint_response [Sinatra::SwaggerExposer::Configuration::SwaggerEndpointResponse]
      # @return [Sinatra::SwaggerExposer::Processing::SwaggerTypeValueProcessor]
      def create_response_value_processor(endpoint_response)
        response_type = endpoint_response.type
        if response_type == TYPE_ARRAY
          processor_for_values = create_processor_for_type('Response', endpoint_response.items, false)
          Sinatra::SwaggerExposer::Processing::SwaggerArrayValueProcessor.new('Response', true, processor_for_values)
        elsif response_type == TYPE_FILE
          # Don't validate the files' content
          nil
        elsif PRIMITIVE_TYPES.include? response_type
          Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValueProcessor.new(
            'Response',
            true,
            response_type,
            nil,
            {}
          )
        elsif response_type
          create_processor_for_type('Response', response_type, false)
        else
          nil
        end
      end

      # Create a parameter processor for a parameter
      # @param parameter [Sinatra::SwaggerExposer::Configuration::SwaggerEndpointParameter]
      # @return [Sinatra::SwaggerExposer::Processing::SwaggerTypeValueProcessor]
      def create_parameter_value_processor(parameter)
        type_name = parameter.type
        if type_name == TYPE_ARRAY
          if PRIMITIVE_TYPES.include? parameter.items
            processor_for_values = Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValueProcessor.new(
              parameter.name,
              false,
              parameter.items,
              parameter.default,
              parameter.params
            )
          else
            processor_for_values = create_processor_for_type(parameter.name, parameter.items, false)
          end
          Sinatra::SwaggerExposer::Processing::SwaggerArrayValueProcessor.new(
            parameter.name,
            parameter.required,
            processor_for_values
          )
        elsif PRIMITIVE_TYPES.include? type_name
          Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValueProcessor.new(
            parameter.name,
            parameter.required,
            type_name,
            parameter.default,
            parameter.params
          )
        else
          create_processor_for_type(parameter.name, parameter.type, parameter.required)
        end
      end

      # Create a type parameter processor for a type parameter
      # @param parameter_name [String] the parameter name
      # @param parameter_type [String] the parameter type
      # @param parameter_required [TrueClass] if the parameter is required
      # @return [Sinatra::SwaggerExposer::Processing::SwaggerTypeValueProcessor]
      def create_processor_for_type(parameter_name, parameter_type, parameter_required)
        attributes_processors = create_attributes_processors_for_type(parameter_type)
        Sinatra::SwaggerExposer::Processing::SwaggerTypeValueProcessor.new(
          parameter_name,
          parameter_required,
          attributes_processors
        )
      end

      # Get attributes processor for a type
      # @param type_name [String] the type name
      # @return [Array<Sinatra::SwaggerExposer::Processing::SwaggerBaseValueProcessor>]
      def create_attributes_processors_for_type(type_name)
        type = @types[type_name]
        attributes_processors = []
        type.properties.each_pair do |property_name, property|
          attributes_processors <<
            create_processor_for_property(
              property_name,
              property,
              type.required.include?(property.name)
            )
        end
        if type.extends
          attributes_processors = attributes_processors + create_attributes_processors_for_type(type.extends)
        end
        attributes_processors
      end

      # Create a processor for a type property
      # @param type_property [Sinatra::SwaggerExposer::Configuration::SwaggerTypeProperty]
      # @return [Sinatra::SwaggerExposer::Processing::SwaggerBaseValueProcessor]
      def create_processor_for_property(name, type_property, required)
        property_type = type_property.type
        if property_type == TYPE_ARRAY
          if PRIMITIVE_TYPES.include? type_property.items
            processor_for_values = Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValueProcessor.new(
              name,
              false,
              type_property.items,
              type_property.properties[:default],
              type_property.properties
            )
          else
            processor_for_values = create_processor_for_type(name, type_property.items, false)
          end
          Sinatra::SwaggerExposer::Processing::SwaggerArrayValueProcessor.new(name, required, processor_for_values)
        elsif PRIMITIVE_TYPES.include? property_type
          Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValueProcessor.new(
            name,
            required,
            property_type,
            type_property.properties[:default],
            type_property.properties
          )
        else
          create_processor_for_type(name, property_type, required)
        end
      end

    end

  end
end
