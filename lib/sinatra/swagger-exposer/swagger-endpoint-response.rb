require_relative 'swagger-invalid-exception'

module Sinatra

  module SwaggerExposer

    class SwaggerEndpointResponse

      def initialize(description, type, known_types)
        # Validate the type
        if type
          if type.is_a? String
            unless known_types.include? type
              raise SwaggerInvalidException.new("Unknown type [#{type}], registered types are #{known_types.join(', ')}")
            end
            @type = type
          elsif type.is_a? Array
            unless type.empty?
              @items = type[0]
              unless known_types.include? @items
                raise SwaggerInvalidException.new("Unknown type [#{@items}], registered types are #{known_types.join(', ')}")
              end
            end
            @type = 'array'
          else
            raise SwaggerInvalidException.new("Type [#{type}] has an unknown type, should be a string or an array")
          end
        end

        if description
          @description = description
        end

      end

      def to_swagger
        result = {}

        if @type
          if @type == 'array'
            schema = {
                :type => 'array'
            }
            if @items
              schema[:items] = {'$ref' => "#/definitions/#{@items}"}
            end
            result[:schema] = schema
          else
            result[:schema] = {'$ref' => "#/definitions/#{@type}"}
          end
        end

        if @description
          result[:description] = @description
        end

        result
      end

    end

  end
end
