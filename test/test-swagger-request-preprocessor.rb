require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-invalid-exception'
require_relative '../lib/sinatra/swagger-exposer/swagger-request-preprocessor'

class TestSwaggerEndpoint < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerRequestPreprocessor do

    include TestUtilities

    def new_rp(processors)
      request_preprocessor = Sinatra::SwaggerExposer::SwaggerRequestPreprocessor.new
      processors.each do |processor|
        request_preprocessor.add_preprocessor processor
      end
      request_preprocessor
    end

    class FakeRequestPreprocessorProcessor

      attr_reader :app, :parsed_body

      def initialize(error_message)
        @error_message = error_message
      end

      def run(app, parsed_body)
        @app = app
        @parsed_body = parsed_body
        if @error_message
          raise Sinatra::SwaggerExposer::SwaggerInvalidException.new(@error_message)
        end
      end
    end

    class FakeRequestPreprocessorRequest

      def initialize(body)
        @body = body
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
      processor = FakeRequestPreprocessorProcessor.new('plop')
      app = FakeRequestPreprocessorApp.new({:head => :ears}, nil)
      result = new_rp([processor]).run(app)
      result[0].must_equal 400
      JSON.parse(result[1]).must_equal({'code' => 400, 'message' => 'plop'})
    end

    it 'should parse the body' do
      processor = FakeRequestPreprocessorProcessor.new(nil)
      app = FakeRequestPreprocessorApp.new({'CONTENT_TYPE' => 'application/json'}, '{"plip": "plop"}')
      result = new_rp([processor]).run(app)
      result.must_equal ''
      app.params['parsed_body'].must_equal({'plip' => 'plop'})
    end

    it 'should not parse a non-json body' do
      processor = FakeRequestPreprocessorProcessor.new(nil)
      app = FakeRequestPreprocessorApp.new({:head => :ears}, '{"plip": "plop"}')
      result = new_rp([processor]).run(app)
      result.must_equal ''
      app.params['parsed_body'].must_equal({})
    end

  end

end
