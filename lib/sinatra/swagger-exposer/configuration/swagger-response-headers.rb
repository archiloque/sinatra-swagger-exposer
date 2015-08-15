require_relative 'swagger-hash-like'
require_relative 'swagger-response-header'

module Sinatra

  module SwaggerExposer

    module Configuration

      # Contain all the declared response headers
      class SwaggerResponseHeaders < SwaggerHashLike

        attr_reader :response_headers

        def initialize
          @response_headers = {}
          super(@response_headers)
        end

        # Add a new swagger response header
        # @param name [String] the type name
        # @param type [Object] the type
        # @param description [String] the description
        def add_response_header(name, type, description)
          name = name.to_s
          check_duplicate(name, 'Response header')
          @response_headers[name] = SwaggerResponseHeader.new(name, type, description)
        end

      end
    end
  end
end
