require 'json'
require 'mime-types'

require_relative '../swagger-invalid-exception'

module Sinatra

  module SwaggerExposer

    module Processing

      # Custom mime types that matches everything when '*' is in list
      class AllMimesTypes

        def like?(other)
          true
        end

      end

      # A processor for a request, apply the parameters processors then execute the query code
      class SwaggerRequestProcessor

        attr_reader :processors_dispatchers, :response_processors, :produces

        # @param produces [Array<String>]
        def initialize(produces = nil)
          @processors_dispatchers = []
          @response_processors = {}
          @produces = produces
          if produces
            @produces_types = produces.collect do |produce|
              if produce == '*'
                [Sinatra::SwaggerExposer::Processing::AllMimesTypes.new]
              else
                MIME::Types[produce]
              end
            end.flatten
          end
        end

        # @param dispatcher [Sinatra::SwaggerExposer::Processing::SwaggerProcessorDispatcher]
        def add_dispatcher(dispatcher)
          @processors_dispatchers << dispatcher
        end

        # @param response_processor [Sinatra::SwaggerExposer::Processing::SwaggerResponseProcessor]
        def add_response_processor(code, response_processor)
          @response_processors[code] = response_processor
        end

        JSON_CONTENT_TYPE = MIME::Types['application/json'].first
        HTML_CONTENT_TYPE = MIME::Types['text/html'].first

        # Run the processor the call the route content
        # @param app the sinatra app being run
        # @param block_params [Array] the block parameters
        # @param block the block containing the route content
        def run(app, block_params, &block)
          parsed_body = {}
          if JSON_CONTENT_TYPE.like?(app.env['CONTENT_TYPE'])
            body = app.request.body.read
            unless body.empty?
              begin
                parsed_body = JSON.parse(body)
              rescue JSON::ParserError => e
                return [400, {:code => 400, :message => e.message}.to_json]
              end
            end
          end
          app.params['parsed_body'] = parsed_body
          unless @processors_dispatchers.empty?
            @processors_dispatchers.each do |processor_dispatcher|
              begin
                processor_dispatcher.process(app, parsed_body)
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

        # Validate the response
        # @param response_body [String] the body
        # @param content_type [String] the content type
        # @param response_status [Integer] the status
        def validate_response(response_body, content_type, response_status)
          validate_response_content_type(content_type, response_status)
          if @response_processors.key?(response_status)
            response_processor = response_processors[response_status]
            if JSON_CONTENT_TYPE.like?(content_type) && response_processor
              response_processor.validate_response(response_body)
            end
          else
            raise SwaggerInvalidException.new("Status with unknown response status [#{response_status}], known statuses are [#{@response_processors.keys.join(', ')}] response value is #{response_body}")
          end
        end

        # Validate a response content type
        # @param content_type [String] the content type to validate
        # @param response_status [Integer] the status
        def validate_response_content_type(content_type, response_status)
          if content_type.nil? && (response_status == 204)
            # No content and no content type => everything is OK
          elsif @produces
            # if there is no content type Sinatra will default to html so we simulate it here
            if content_type.nil? && @produces_types.any? { |produce| produce.like?(HTML_CONTENT_TYPE) }
              content_type = HTML_CONTENT_TYPE
            end
            unless @produces_types.any? { |produce| produce.like?(content_type) }
              raise SwaggerInvalidException.new("Undeclared content type [#{content_type}], declared content type are [#{@produces.join(', ')}]")
            end
          elsif !JSON_CONTENT_TYPE.like?(content_type)
            raise SwaggerInvalidException.new("Undeclared content type [#{content_type}], if no declaration for the endpoint you should only return json")
          end
        end

      end
    end
  end
end