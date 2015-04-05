require_relative 'swagger-utilities'
require_relative 'swagger-invalid-exception'

module Sinatra

  module SwaggerExposer

    class SwaggerEndpointResponse

      include SwaggerUtilities

      def initialize(type, description, known_types)
        get_type(type, known_types + PRIMITIVE_TYPES)
        if description
          @description = description
        end
      end

      def to_swagger
        result = {}

        if @type
          if @type == 'array'
            schema = {:type => 'array'}
            if @items
              if PRIMITIVE_TYPES.include? @items
                schema[:items] = {:type => @items}
              else
                schema[:items] = {'$ref' => "#/definitions/#{@items}"}
              end
            end
            result[:schema] = schema
          else
            if PRIMITIVE_TYPES.include? @type
              result[:schema] = {:type => @type}
            else
              result[:schema] = {'$ref' => "#/definitions/#{@type}"}
            end
          end
        end

        if @description
          result[:description] = @description
        end

        result
      end

      def to_s
        {
            :type => @type,
            :items => @items,
            :description => @description,
        }.to_json
      end


    end

  end
end
