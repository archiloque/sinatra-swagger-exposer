require_relative '../swagger-parameter-helper'
require_relative '../swagger-invalid-exception'
require_relative '../configuration/swagger-endpoint-parameter'

module Sinatra

  module SwaggerExposer

    module Processing

      # Process the parameters for validation and enrichment
      class SwaggerParameterProcessor

        include Sinatra::SwaggerExposer::SwaggerParameterHelper

        # Initialize
        # @param how_to_pass [String] how to pass the parameter
        # @param value_processor [Sinatra::SwaggerExposer::Processing::SwaggerBaseValueProcessor] the parameter processor
        def initialize(how_to_pass, value_processor)
          @how_to_pass = how_to_pass
          @value_processor = value_processor
          @useful = @value_processor.useful?
        end

        # Is the processor useful
        # @return [TrueClass]
        def useful?
          @useful
        end

        def run(app, parsed_body)
          case @how_to_pass
            when HOW_TO_PASS_PATH
              # can't validate
            when HOW_TO_PASS_QUERY
              @value_processor.validate(app.params)
            when HOW_TO_PASS_HEADER
              @value_processor.validate(app.headers)
            when HOW_TO_PASS_BODY
              @value_processor.validate(parsed_body || {})
          end
        end

      end
    end
  end
end