require_relative '../swagger-parameter-helper'

module Sinatra

  module SwaggerExposer

    module Processing

      # Process a response
      class SwaggerResponseProcessor

        include Sinatra::SwaggerExposer::SwaggerParameterHelper

        attr_reader :endpoint_response, :processor

        # Initialize
        # @param endpoint_response [Sinatra::SwaggerExposer::Configuration::SwaggerEndpointResponse]
        # @param processor [Sinatra::SwaggerExposer::Processing::SwaggerTypeValueProcessor]
        def initialize(endpoint_response, processor)
          @endpoint_response = endpoint_response
          @processor = processor
        end

        # Test if the processor is useful
        # @return [TrueClass]
        def useful?
          (@endpoint_response && (@endpoint_response.type != TYPE_FILE)) || @processor
        end

        # Validate a response
        # @param response_body [String] the body
        def validate_response(response_body)
          parsed_response_body = nil
          begin
            parsed_response_body = JSON.parse(response_body)
          rescue JSON::ParserError => e
            raise SwaggerInvalidException.new("Response is not a valid json [#{response_body}]")
          end
          if @processor
            @processor.validate_value(parsed_response_body)
          end
        end

      end
    end
  end
end