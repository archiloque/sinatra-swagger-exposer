require_relative '../minitest-helper'
require_relative '../test-utilities'

require_relative '../../lib/sinatra/swagger-exposer/swagger-invalid-exception'
require_relative '../../lib/sinatra/swagger-exposer/processing/swagger-response-processor'

class TestSwaggerRequestProcessor < Minitest::Test

  describe Sinatra::SwaggerExposer::Processing::SwaggerResponseProcessor do

    include TestUtilities

    class FakeSwaggerEndpointResponseForTestSwaggerRequestProcessor

      def initialize(type)
        @type = type
      end

      def type
        @type
      end
    end

    class FakeSwaggerResponseProcessorForTestSwaggerRequestProcessor

      attr_reader :last_value

      def validate_value(value)
        @last_value = value
      end

    end

    # @param endpoint_response [Sinatra::SwaggerExposer::Configuration::SwaggerEndpointResponse]
    # @param processor [Sinatra::SwaggerExposer::Processing::SwaggerTypeValueProcessor]
    # @return [Sinatra::SwaggerExposer::Processing::SwaggerResponseProcessor]
    def new_rp(endpoint_response, processor)
      Sinatra::SwaggerExposer::Processing::SwaggerResponseProcessor.new(endpoint_response, processor)
    end

    it 'should parse the body' do
      new_rp(nil, nil).validate_response('{}')
    end

    it 'should fail to parse an invalid body' do
      must_raise_swag_and_equal(
        -> { new_rp(nil, nil).validate_response('') },
        'Response is not a valid json []'
      )
    end

    it 'should calculate usefulness' do
      new_rp(nil, nil).useful?.must_be_nil

      new_rp(FakeSwaggerEndpointResponseForTestSwaggerRequestProcessor.new(Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_FILE), nil).useful?.must_be_nil
      new_rp(FakeSwaggerEndpointResponseForTestSwaggerRequestProcessor.new('no file'), nil).useful?.must_equal(TRUE)

      new_rp(nil, TRUE).useful?.must_equal(TRUE)
      new_rp(FakeSwaggerEndpointResponseForTestSwaggerRequestProcessor.new(Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_FILE), TRUE).useful?.must_equal(TRUE)
      new_rp(FakeSwaggerEndpointResponseForTestSwaggerRequestProcessor.new('no file'), TRUE).useful?.must_equal(TRUE)
    end

    it 'should validate the response' do
      response_processor = FakeSwaggerResponseProcessorForTestSwaggerRequestProcessor.new
      new_rp(nil, response_processor).validate_response('{"a": "b"}')
      response_processor.last_value.must_equal({'a' => 'b'})
    end


  end

end
