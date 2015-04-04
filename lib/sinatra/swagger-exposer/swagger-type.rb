require_relative 'swagger-invalid-exception'
require_relative 'swagger-type-property'

module Sinatra

  module SwaggerExposer

    # A type
    class SwaggerType

      def initialize(type_name, type_content)
        @properties = process_properties(type_name, type_content)
        @required = process_required(type_name, type_content, @properties.keys)
        @example = process_example(type_name, type_content, @properties.keys)
      end

      def process_properties(type_name, type_content)
        if !type_content.key?(:properties)
          {}
        elsif !type_content[:properties].is_a? Hash
          raise SwaggerInvalidException.new("Swagger: attribute [properties] of #{type_name} is not an hash: #{type_content[:properties]}")
        else
          result = {}
          type_content[:properties].each_pair do |property_name, property_properties|
            result[property_name.to_s] = SwaggerTypeProperty.new(type_name, property_name, property_properties)
          end
          result
        end
      end

      def process_required(type_name, type_content, properties_names)
        if !type_content.key?(:required)
          []
        elsif !type_content[:required].is_a? Array
          raise SwaggerInvalidException.new("Swagger: attribute [required] of #{type_name} is not an array: #{type_content[:required]}")
        else
          type_content[:required].each do |property_name|
            property_name = property_name.to_s
            unless properties_names.include? property_name
              raise SwaggerInvalidException.new("Swagger: required property [#{property_name}] of [#{type_name}] is unknown, known properties: #{properties_names.join(', ')}")
            end
          end
          type_content[:required]
        end
      end

      def process_example(type_name, type_content, properties_names)
        if !type_content.key?(:example)
          []
        elsif !type_content[:example].is_a? Hash
          raise SwaggerInvalidException.new("Swagger: attribute [example] of #{type_name} is not an hash: #{type_content[:example]}")
        else
          type_content[:example].each_pair do |property_name, property_value|
            property_name = property_name.to_s
            unless properties_names.include? property_name
              raise SwaggerInvalidException.new("Swagger: example property [#{property_name}] with value [#{property_value}] of [#{type_name}] is unknown, known properties: #{properties_names.join(', ')}")
            end
          end
          type_content[:example]
        end
      end

      def to_swagger
        result = {}

        unless @properties.empty?
          swagger_properties = {}
          @properties.collect do |key, value|
            swagger_properties[key] = value.to_swagger
          end
          result[:properties] = swagger_properties
        end

        unless @required.empty?
          result[:required] = @required
        end

        unless @example.empty?
          result[:example] = @example
        end

        result
      end

    end

  end
end
