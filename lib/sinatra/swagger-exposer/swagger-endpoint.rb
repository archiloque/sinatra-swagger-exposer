require_relative 'swagger-utilities'

module Sinatra

  module SwaggerExposer

    # An endpoint
    class SwaggerEndpoint

      include SwaggerUtilities

      attr_reader :path, :type

      def initialize(type, path, responses, summary, description, tags)
        @type = type
        @path = path

        @responses = responses

        @attributes = {}
        if summary
          @attributes[:summary] = summary
        end
        if description
          @attributes[:description] = description
        end
        if tags
          @attributes[:tags] = tags
        end

      end

      def to_swagger
        result = {
            produces: ['application/json'],
        }.merge(@attributes)

        # add the responses
        unless @responses.empty?
          result[:responses] = hash_to_swagger(@responses)
        end

        result
      end

    end

  end
end
