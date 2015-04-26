require_relative 'swagger-utilities'
require_relative 'swagger-invalid-exception'

module Sinatra

  module SwaggerExposer

    class SwaggerEndpointResponse

      include SwaggerUtilities

      RESPONSE_PRIMITIVES_FILES = PRIMITIVE_TYPES + [TYPE_FILE]

      def initialize(type, description, known_types)
        get_type(type, known_types + RESPONSE_PRIMITIVES_FILES)
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
              if RESPONSE_PRIMITIVES_FILES.include? @items
                schema[:items] = {:type => @items}
              else
                schema[:items] = ref_to_type(@items)
              end
            end
            result[:schema] = schema
          else
            if RESPONSE_PRIMITIVES_FILES.include? @type
              result[:schema] = {:type => @type}
            else
              result[:schema] = ref_to_type(@type)
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
