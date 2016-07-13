require_relative '../minitest-helper'
require_relative '../test-utilities'

require_relative '../../lib/sinatra/swagger-exposer/swagger-invalid-exception'
require_relative '../../lib/sinatra/swagger-exposer/processing/swagger-request-processor'

class TestSwaggerRequestProcessor < Minitest::Test

  describe Sinatra::SwaggerExposer::Processing::SwaggerRequestProcessor do

    include TestUtilities

    # @param dispatcher [Sinatra::SwaggerExposer::Processing::SwaggerProcessorDispatcher]
    # @param produces [Array<String>]
    # @return [Sinatra::SwaggerExposer::Processing::SwaggerRequestProcessor]
    def new_rp(dispatcher, produces = nil)
      request_processor = Sinatra::SwaggerExposer::Processing::SwaggerRequestProcessor.new(produces)
      if dispatcher
        request_processor.add_dispatcher dispatcher
      end
      request_processor
    end

    class FakeProcessorDispatcher

      attr_reader :app, :parsed_body

      def initialize(error_message)
        @error_message = error_message
      end

      def process(app, parsed_body)
        @app = app
        @parsed_body = parsed_body
        if @error_message
          raise Sinatra::SwaggerExposer::SwaggerInvalidException.new(@error_message)
        end
      end
    end

    class FakeRequestProcessorRequest

      def initialize(body)
        @body = StringIO.new(body)
      end

      def body
        if @body
          @body
        else
          raise Exception.new
        end
      end

    end

    class FakeRequestProcessorApp

      attr_reader :env, :request, :params, :recorded_content_type

      def initialize(headers, body)
        @env = headers
        @request = FakeRequestProcessorRequest.new(body)
        @params = {}
      end

      def content_type(content_type)
        @recorded_content_type = content_type
      end

    end

    class FakeResponseProcessor

      attr_reader :response_body

      def validate_response(response_body)
        @response_body = response_body
      end

    end

    it 'should fail when the processor fail' do
      processor_dispatcher = FakeProcessorDispatcher.new('plop')
      app = FakeRequestProcessorApp.new({:head => :ears}, '')
      result = new_rp(processor_dispatcher).run(app, [])
      result[0].must_equal 400
      JSON.parse(result[1]).must_equal({'code' => 400, 'message' => 'plop'})
    end

    it 'should parse the body' do
      processor_dispatcher = FakeProcessorDispatcher.new(nil)
      app = FakeRequestProcessorApp.new({'CONTENT_TYPE' => 'application/json'}, '{"plip": "plop"}')
      result = new_rp(processor_dispatcher).run(app, [])
      result.must_equal ''
      app.params['parsed_body'].must_equal({'plip' => 'plop'})
    end

    it 'should parse the body when in UTF-8' do
      processor = FakeProcessorDispatcher.new(nil)
      app = FakeRequestProcessorApp.new({'CONTENT_TYPE' => 'application/json; charset=utf-8'}, '{"plip": "plop"}')
      result = new_rp(processor).run(app, [])
      result.must_equal ''
      app.params['parsed_body'].must_equal({'plip' => 'plop'})
    end

    it 'should not parse a non-json body' do
      processor_dispatcher = FakeProcessorDispatcher.new(nil)
      app = FakeRequestProcessorApp.new({:head => :ears}, '{"plip": "plop"}')
      result = new_rp(processor_dispatcher).run(app, [])
      result.must_equal ''
      app.params['parsed_body'].must_equal({})
    end

    it 'should fail to parse an invalid body' do
      invalid_body = '{"plip: "plop"}'
      # the error message contains a code id that is changing between version
      # so we must produce it ourself to be sure it's ok
      expected_message = nil
      begin
        JSON.parse(invalid_body)
      rescue Exception => e
        expected_message = e.message
      end
      processor_dispatcher = FakeProcessorDispatcher.new(nil)
      app = FakeRequestProcessorApp.new({'CONTENT_TYPE' => 'application/json'}, invalid_body)
      result = new_rp(processor_dispatcher).run(app, [])
      result.must_equal [400, {"code": 400, "message": expected_message}.to_json]
    end

    it 'should fail with an unknown content type' do
      must_raise_swag_and_equal(
        -> { new_rp(nil).validate_response(nil, 'application/xml', 200) },
        'Undeclared content type [application/xml], if no declaration for the endpoint you should only return json'
      )
      must_raise_swag_and_equal(
        -> { new_rp(nil, ['application/xml']).validate_response(nil, 'image/png', 200) },
        'Undeclared content type [image/png], declared content type are [application/xml]'
      )
    end

    it 'should fail with an unknown status' do
      must_raise_swag_and_equal(
        -> { new_rp(nil).validate_response('{}', 'application/json', 204) },
        'Status with unknown response status [204], known statuses are [] response value is {}'
      )
    end

    it 'should be ok with a json content type' do
      request_processor = new_rp(nil)
      response_processor = FakeResponseProcessor.new
      request_processor.add_response_processor(200, response_processor)
      request_processor.validate_response('plop', 'application/json', 200)
      response_processor.response_body.must_equal 'plop'
    end

    it 'should be ok with an known content type' do
      request_processor = new_rp(nil, ['application/xml'])
      response_processor = FakeResponseProcessor.new
      request_processor.add_response_processor(200, response_processor)
      request_processor.validate_response('plop', 'application/xml', 200)
      response_processor.response_body.must_be_nil
    end

    it 'should be ok with no content type for 204' do
      request_processor = new_rp(nil)
      response_processor = FakeResponseProcessor.new
      request_processor.add_response_processor(204, response_processor)
      request_processor.validate_response('', nil, 204)
      response_processor.response_body.must_be_nil
    end

    it 'should be ok with a * content type' do
      request_processor = new_rp(nil, ['*'])
      response_processor = FakeResponseProcessor.new
      request_processor.add_response_processor(200, response_processor)
      request_processor.validate_response('plop', 'application/xml', 200)
      response_processor.response_body.must_be_nil
    end

    it 'should suppose no content type means html when we declared an html content' do
      request_processor = new_rp(nil, ['text/html'])
      response_processor = FakeResponseProcessor.new
      request_processor.add_response_processor(200, response_processor)
      request_processor.validate_response('plop', nil, 200)
      response_processor.response_body.must_be_nil
    end

  end

end
