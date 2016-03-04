require_relative '../swagger-parameter-helper'

module Sinatra

  module SwaggerExposer

    module Processing

      # Dispatch content to a processor
      class SwaggerProcessorDispatcher

        attr_reader :how_to_pass, :processor

        include Sinatra::SwaggerExposer::SwaggerParameterHelper

        # Initialize
        # @param how_to_pass how the value should be passed to the processor
        # @param processor [Sinatra::SwaggerExposer::Processing::SwaggerBaseValueProcessor] processor for the values
        def initialize(how_to_pass, processor)
          @how_to_pass = how_to_pass
          @processor = processor
        end

        def useful?
          (@how_to_pass != HOW_TO_PASS_PATH) && @processor.useful?
        end

        # Process the value
        def process(app, parsed_body)
          case @how_to_pass
            when HOW_TO_PASS_PATH
              # can't validate
            when HOW_TO_PASS_QUERY
              @processor.process(app.params)
            when HOW_TO_PASS_HEADER
              @processor.process(app.headers)
            when HOW_TO_PASS_BODY
              @processor.process(parsed_body || {})
          end
        end

      end
    end
  end
end