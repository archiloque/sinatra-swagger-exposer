module Sinatra

  module SwaggerExposer

    # An endpoint
    class SwaggerEndpoint

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
          result_responses = {}
          @responses.each_pair do |response_code, response_value|
            result_responses[response_code] = response_value.to_swagger
          end
          result[:responses] = result_responses
        end

        result
      end

    end

  end
end
