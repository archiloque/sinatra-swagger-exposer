require_relative '../swagger-parameter-helper'

module Sinatra

  module SwaggerExposer

    module Processing

      # Dispatch content to a preprocessor
      class SwaggerPreprocessorDispatcher

        attr_reader :how_to_pass, :preprocessor

        include Sinatra::SwaggerExposer::SwaggerParameterHelper

        # Initialize
        # @param how_to_pass how the value should be passed to the preprocessor
        # @param preprocessor [Sinatra::SwaggerExposer::Processing::SwaggerBaseValuePreprocessor] processor for the values
        def initialize(how_to_pass, preprocessor)
          @how_to_pass = how_to_pass
          @preprocessor = preprocessor
        end

        def useful?
          (@how_to_pass != HOW_TO_PASS_PATH) && @preprocessor.useful?
        end

        # Process the value
        def process(app, parsed_body)
          case @how_to_pass
            when HOW_TO_PASS_PATH
              # can't validate
            when HOW_TO_PASS_QUERY
              @preprocessor.process(app.params)
            when HOW_TO_PASS_HEADER
              @preprocessor.process(app.headers)
            when HOW_TO_PASS_BODY
              @preprocessor.process(parsed_body || {})
          end
        end

      end
    end
  end
end