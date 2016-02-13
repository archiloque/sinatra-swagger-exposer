require_relative '../swagger-invalid-exception'

require_relative 'swagger-configuration-utilities'
require_relative 'swagger-parameter-validation-helper'

module Sinatra

  module SwaggerExposer

    module Configuration
      # A property of a type
      class SwaggerTypeProperty

        attr_reader :name, :type, :items

        include SwaggerConfigurationUtilities
        include SwaggerParameterValidationHelper

        OTHER_PROPERTIES = [:example, :description, :format, :minLength, :maxLength, :default]
        PROPERTIES = [:type] + OTHER_PROPERTIES

        def initialize(type_name, property_name, property_properties, known_types)
          @name = property_name

          unless property_properties.is_a? Hash
            raise SwaggerInvalidException.new("Property [#{property_name}] value [#{property_properties}] of [#{type_name}] should be a hash")
          end

          if property_properties.key? :type
            get_type(property_properties[:type], PRIMITIVE_TYPES + known_types)
          end

          white_list_params(property_properties, PROPERTIES)

          validate_params(@type, property_properties)

          @other_properties = property_properties.select do |key, value|
            OTHER_PROPERTIES.include? key
          end
        end

        def properties
          @other_properties
        end

        def to_swagger
          result = @other_properties.clone

          if @type
            if @type == TYPE_ARRAY
              result[:type] = TYPE_ARRAY
              if @items
                if PRIMITIVE_TYPES.include? @items
                  result[:items] = {:type => @items}
                else
                  result[:items] = ref_to_type(@items)
                end
              end
            else
              if PRIMITIVE_TYPES.include? @type
                result[:type] = @type
              else
                result['$ref'] = "#/definitions/#{@type}"
              end
            end
          end

          result
        end

        def to_s
          {
            :name => @name,
            :type => @type,
            :items => @items,
            :other_properties => @other_properties,
          }.to_json
        end

      end
    end
  end
end
