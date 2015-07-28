require_relative '../minitest-helper'
require_relative '../test-utilities'

require_relative '../../lib/sinatra/swagger-exposer/swagger-invalid-exception'
require_relative '../../lib/sinatra/swagger-exposer/processing/swagger-request-preprocessor'

class TestSwaggerRequestPreprocessor < Minitest::Test

  describe Sinatra::SwaggerExposer::Processing::SwaggerRequestPreprocessor do

    include TestUtilities

    def new_rp(dispatcher)
      request_preprocessor = Sinatra::SwaggerExposer::Processing::SwaggerRequestPreprocessor.new
      request_preprocessor.add_dispatcher dispatcher
      request_preprocessor
    end

    class FakePreprocessorDispatcher

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

    class FakeRequestPreprocessorRequest

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

    class FakeRequestPreprocessorApp

      attr_reader :env, :request, :params, :recorded_content_type

      def initialize(headers, body)
        @env = headers
        @request = FakeRequestPreprocessorRequest.new(body)
        @params = {}
      end

      def content_type(content_type)
        @recorded_content_type = content_type
      end

    end

    it 'should fail when the processor fail' do
      preprocessor_dispatcher = FakePreprocessorDispatcher.new('plop')
      app = FakeRequestPreprocessorApp.new({:head => :ears}, '')
      result = new_rp(preprocessor_dispatcher).run(app, [])
      result[0].must_equal 400
      JSON.parse(result[1]).must_equal({'code' => 400, 'message' => 'plop'})
    end

    it 'should parse the body' do
      preprocessor_dispatcher = FakePreprocessorDispatcher.new(nil)
      app = FakeRequestPreprocessorApp.new({'CONTENT_TYPE' => 'application/json'}, '{"plip": "plop"}')
      result = new_rp(preprocessor_dispatcher).run(app, [])
      result.must_equal ''
      app.params['parsed_body'].must_equal({'plip' => 'plop'})
    end

    it 'should parse the body when in UTF-8' do
      preprocessor = FakePreprocessorDispatcher.new(nil)
      app = FakeRequestPreprocessorApp.new({'CONTENT_TYPE' => 'application/json; charset=utf-8'}, '{"plip": "plop"}')
      result = new_rp(preprocessor).run(app, [])
      result.must_equal ''
      app.params['parsed_body'].must_equal({'plip' => 'plop'})
    end

    it 'should not parse a non-json body' do
      preprocessor_dispatcher = FakePreprocessorDispatcher.new(nil)
      app = FakeRequestPreprocessorApp.new({:head => :ears}, '{"plip": "plop"}')
      result = new_rp(preprocessor_dispatcher).run(app, [])
      result.must_equal ''
      app.params['parsed_body'].must_equal({})
    end

    it 'should fail to parse an invalid body' do
      preprocessor_dispatcher = FakePreprocessorDispatcher.new(nil)
      app = FakeRequestPreprocessorApp.new({'CONTENT_TYPE' => 'application/json'}, '{"plip: "plop"}')
      result = new_rp(preprocessor_dispatcher).run(app, [])
      result.must_equal [400, {"code":400,"message":"757: unexpected token at '{\"plip: \"plop\"}'"}.to_json]
    end

  end

end
