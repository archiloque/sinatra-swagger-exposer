require 'json'

require_relative 'swagger-invalid-exception'

module Sinatra

  module SwaggerExposer

    # A preprocessor for a request, apply the parameter preprocessor then execute the query code
    class SwaggerRequestPreprocessor

      attr_reader :preprocessors

      def initialize
        @preprocessors = []
      end

      def add_preprocessor(preprocessor)
        @preprocessors << preprocessor
      end

      VALID_JSON_CONTENT_TYPES = ['application/json', 'application/json; charset=utf-8']

      # Run the preprocessor the call the route content
      # @param app the sinatra app being run
      # @params block_params [Array] the block parameters
      # @param block the block containing the route content
      def run(app, block_params, &block)
        parsed_body = {}
        if VALID_JSON_CONTENT_TYPES.include? app.env['CONTENT_TYPE']
          body = app.request.body.read
          unless body.empty?
            parsed_body = JSON.parse(body)
          end
        end
        app.params['parsed_body'] = parsed_body
        unless @preprocessors.empty?
          @preprocessors.each do |preprocessor|
            begin
              preprocessor.run(app, parsed_body)
            rescue SwaggerInvalidException => e
              app.content_type :json
              return [400, {:code => 400, :message => e.message}.to_json]
            end
          end
        end
        if block
          # Execute the block in the context of the app
          app.instance_exec(*block_params, &block)
        else
          ''
        end
      end

    end

  end
end