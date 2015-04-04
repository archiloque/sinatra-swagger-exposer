require_relative 'swagger-invalid-exception'

module Sinatra

  module SwaggerExposer

    # A property of a type
    class SwaggerTypeProperty

      KNOWN_PRIMITIVE_TYPES = [
          'integer',
          'long',
          'float',
          'double',
          'string',
          'byte',
          'boolean',
          'date',
          'dateTime',
          'password'
      ]

      OTHER_PROPERTIES = [:example, :description, :format]
      KNOWN_PROPERTIES = [:type] + OTHER_PROPERTIES

      def initialize(type_name, property_name, property_properties)
        @name = property_name

        # Validate the properties
        property_properties.each_pair do |key, value|
          unless KNOWN_PROPERTIES.include? key
            raise SwaggerInvalidException.new("Unknown property [#{key}] for [#{property_name}] of [#{type_name}] with value [#{value}], known properties are #{KNOWN_PROPERTIES.join(', ')}")
          end
        end

        if property_properties.key? :type
          @type = property_properties[:type]
          if @type.is_a? String
            validate_type(@type, type_name)
          elsif @type.is_a? Class
            @type = attribute_to_s(@type)
            validate_type(@type, type_name)
          elsif @type.is_a? Array
            if @type.empty?
              raise SwaggerInvalidException.new("Type [#{type_name}] is an empty array, you should specify a type as the array content")
            elsif @type.length > 1
              raise SwaggerInvalidException.new("Type [#{@type}] of [#{type_name}] has more than one entry, it should only have one")
            else
              @items = attribute_to_s(@type[0])
              validate_type(@items, type_name)
            end
            @type = 'array'
          else
            raise SwaggerInvalidException.new("Type [#{@type}] of [#{type_name}] has an unknown type, should be a class, a string or an array")
          end
        end

        @other_properties = property_properties.select do |key, value|
          OTHER_PROPERTIES.include? key
        end

      end

      def validate_type(type, type_name)
        unless KNOWN_PRIMITIVE_TYPES.include? type
          raise SwaggerInvalidException.new("Unknown type [#{type}] of [#{type_name}], possible types are #{KNOWN_PRIMITIVE_TYPES.join(', ')}")
        end
      end

      def attribute_to_s(value)
        if value.is_a? Class
          value.to_s.downcase
        else
          value
        end
      end

      def to_swagger
        result = @other_properties.clone
        if @type
          result[:type] = @type
          if @items
            result[:items] = @items
          end
        end
        result
      end

    end

  end
end
