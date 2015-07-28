require_relative '../swagger-parameter-helper'
require_relative '../swagger-invalid-exception'
require_relative '../configuration/swagger-endpoint-parameter'

module Sinatra

  module SwaggerExposer

    module Processing

      # Process the parameters for validation and enrichment
      class SwaggerParameterPreprocessor

        include Sinatra::SwaggerExposer::SwaggerParameterHelper

        # Initialize
        # @param how_to_pass [String] how to pass the parameter
        # @param value_preprocessor [Sinatra::SwaggerExposer::Processing::SwaggerBaseValuePreprocessor] the parameter processor
        def initialize(how_to_pass, value_preprocessor)
          @how_to_pass = how_to_pass
          @value_preprocessor = value_preprocessor
          @useful = @value_preprocessor.useful?
        end

        # Is the preprocessor useful
        # @return [TrueClass]
        def useful?
          @useful
        end

        def run(app, parsed_body)
          case @how_to_pass
            when HOW_TO_PASS_PATH
              # can't validate
            when HOW_TO_PASS_QUERY
              @value_preprocessor.validate(app.params)
            when HOW_TO_PASS_HEADER
              @value_preprocessor.validate(app.headers)
            when HOW_TO_PASS_BODY
              @value_preprocessor.validate(parsed_body || {})
          end
        end

      end
    end
  end
end