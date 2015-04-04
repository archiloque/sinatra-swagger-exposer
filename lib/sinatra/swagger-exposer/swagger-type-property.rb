require_relative 'swagger-invalid-exception'

module Sinatra

  module SwaggerExposer

    # A property of a type
    class SwaggerTypeProperty

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
          elsif @type.is_a? Class
            @type = attribute_to_s(@type)
          elsif @type.is_a? Array
            unless @type.empty?
              @items = attribute_to_s(@type[0])
            end
            @type = 'array'
          else
            raise SwaggerInvalidException.new("Type [#{@type}] of [#{type_name}] has an unknown type, should be a string or an array")
          end
        end

        @other_properties = property_properties.select do |key, value|
          OTHER_PROPERTIES.include? key
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
