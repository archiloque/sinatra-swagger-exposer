require_relative '../swagger-invalid-exception'

require_relative 'swagger-parameter-validation-helper'
require_relative 'swagger-type-property'
require_relative 'swagger-configuration-utilities'

module Sinatra

  module SwaggerExposer

    module Configuration

      class SwaggerResponseHeader

        include SwaggerConfigurationUtilities
        include SwaggerParameterValidationHelper

        attr_reader :type, :name, :description

        PRIMITIVE_HEADERS_TYPES = [
          TYPE_STRING,
          TYPE_NUMBER,
          TYPE_INTEGER,
          TYPE_BOOLEAN,
        ]

        # Create a new instance
        # @param name [String] the name
        # @param description [String] the description
        # @param type [String] the type name
        def initialize(name, type, description)
          check_name(name)
          @name = name

          if description
            @description = description
          end

          get_type(type, PRIMITIVE_HEADERS_TYPES)
        end


        # Return the swagger version
        # @return [Hash]
        def to_swagger
          result = {
            :type => @type,
          }

          if @description
            result[:description] = @description
          end

          result
        end

        def to_s
          {
            :name => @name,
            :type => @type,
            :description => @description,
          }.to_json
        end

      end
    end
  end
end
