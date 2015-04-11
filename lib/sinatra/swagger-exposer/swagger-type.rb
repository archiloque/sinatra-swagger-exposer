require_relative 'swagger-invalid-exception'
require_relative 'swagger-type-property'
require_relative 'swagger-utilities'

module Sinatra

  module SwaggerExposer

    # A type
    class SwaggerType

      include SwaggerUtilities

      PROPERTY_PROPERTIES = :properties
      PROPERTY_REQUIRED = :required
      PROPERTY_EXAMPLE = :example
      PROPERTY_EXTENDS = :extends
      PROPERTIES = [PROPERTY_PROPERTIES, PROPERTY_REQUIRED, PROPERTY_EXAMPLE, PROPERTY_EXTENDS]

      def initialize(type_name, type_properties, known_types)
        white_list_params(type_properties, PROPERTIES)
        @properties = process_properties(type_name, type_properties, known_types)
        @required = process_required(type_name, type_properties, @properties.keys)
        @example = process_example(type_name, type_properties, @properties.keys)
        @extends = process_extends(type_properties, known_types)
      end

      def process_properties(type_name, type_content, known_types)
        possible_value = check_attribute_empty_or_bad(type_name, type_content, PROPERTY_PROPERTIES, Hash)
        if possible_value
          possible_value
        else
          result = {}
          type_content[PROPERTY_PROPERTIES].each_pair do |property_name, property_properties|
            result[property_name.to_s] = SwaggerTypeProperty.new(type_name, property_name, property_properties, known_types)
          end
          result
        end
      end

      def process_required(type_name, type_content, properties_names)
        possible_value = check_attribute_empty_or_bad(type_name, type_content, PROPERTY_REQUIRED, Array)
        if possible_value
          possible_value
        else
          type_content[PROPERTY_REQUIRED].each do |property_name|
            property_name = property_name.to_s
            unless properties_names.include? property_name
              raise SwaggerInvalidException.new("Required property [#{property_name}] of [#{type_name}] is unknown#{list_or_none(properties_names, 'properties')}")
            end
          end
          type_content[PROPERTY_REQUIRED]
        end
      end

      def process_example(type_name, type_content, properties_names)
        possible_value = check_attribute_empty_or_bad(type_name, type_content, PROPERTY_EXAMPLE, Hash)
        if possible_value
          possible_value
        else
          type_content[PROPERTY_EXAMPLE].each_pair do |property_name, property_value|
            property_name = property_name.to_s
            unless properties_names.include? property_name
              raise SwaggerInvalidException.new("Example property [#{property_name}] with value [#{property_value}] of [#{type_name}] is unknown#{list_or_none(properties_names, 'properties')}")
            end
          end
          type_content[PROPERTY_EXAMPLE]
        end
      end

      def check_attribute_empty_or_bad(type_name, type_content, attribute_name, attribute_class)
        if !type_content.key?(attribute_name)
          attribute_class.new
        elsif !type_content[attribute_name].is_a? attribute_class
          raise SwaggerInvalidException.new("Attribute [#{attribute_name}] of #{type_name} is not an hash: #{type_content[attribute_name]}")
        end
      end

      def process_extends(type_properties, known_types)
        if type_properties.key? PROPERTY_EXTENDS
          check_type(type_properties[PROPERTY_EXTENDS], known_types)
          @extends = type_properties[PROPERTY_EXTENDS]
        end
      end

      def to_swagger
        result = {:type => 'object'}

        unless @properties.empty?
          result[PROPERTY_PROPERTIES] = hash_to_swagger(@properties)
        end

        unless @required.empty?
          result[PROPERTY_REQUIRED] = @required
        end

        unless @example.empty?
          result[PROPERTY_EXAMPLE] = @example
        end

        if @extends
          result = {
              :allOf => [
                ref_to_type(@extends),
                result
              ]
          }
        end

        result
      end

      def to_s
        {
            :properties => @properties,
            :required => @required,
            :example => @example,
        }.to_json
      end


    end

  end
end
