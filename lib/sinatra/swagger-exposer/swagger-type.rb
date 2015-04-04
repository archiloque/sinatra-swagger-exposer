require_relative 'swagger-invalid-exception'
require_relative 'swagger-type-property'
require_relative 'swagger-utilities'

module Sinatra

  module SwaggerExposer

    # A type
    class SwaggerType

      include SwaggerUtilities

      def initialize(type_name, type_content)
        @properties = process_properties(type_name, type_content)
        @required = process_required(type_name, type_content, @properties.keys)
        @example = process_example(type_name, type_content, @properties.keys)
      end

      def process_properties(type_name, type_content)
        possible_value = check_attribute_empty_or_bad(type_name, type_content, :properties, Hash)
        if possible_value
          possible_value
        else
          result = {}
          type_content[:properties].each_pair do |property_name, property_properties|
            result[property_name.to_s] = SwaggerTypeProperty.new(type_name, property_name, property_properties)
          end
          result
        end
      end

      def process_required(type_name, type_content, properties_names)
        possible_value = check_attribute_empty_or_bad(type_name, type_content, :required, Array)
        if possible_value
          possible_value
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
        possible_value = check_attribute_empty_or_bad(type_name, type_content, :example, Hash)
        if possible_value
          possible_value
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

      def check_attribute_empty_or_bad(type_name, type_content, attribute_name, attribute_class)
        if !type_content.key?(attribute_name)
          attribute_class.new
        elsif !type_content[attribute_name].is_a? attribute_class
          raise SwaggerInvalidException.new("Swagger: attribute [#{attribute_name}] of #{type_name} is not an hash: #{type_content[attribute_name]}")
        end
      end

      def to_swagger
        result = {}

        unless @properties.empty?
          result[:properties] = hash_to_swagger(@properties)
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
