require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-request-processor-creator'
require_relative '../lib/sinatra/swagger-exposer/configuration/swagger-types'

class TestSwaggerRequestProcessorCreator < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerProcessorCreator do

    include TestUtilities

    class FakeSwaggerEndpointForTestSwaggerRequestProcessorCreator

      attr_reader :parameters, :produces, :responses

      def initialize(parameters, responses = {}, produces = [])
        @parameters = parameters
        @responses = responses
        @produces = produces
      end

    end

    class FakeEndpointResponseForTestSwaggerRequestProcessorCreator

      attr_reader :type, :items

      def initialize(type, items = nil)
        @type = type
        @items = items
      end

    end

    def create_request_processor(types, parameters, responses = {}, produces = [])
      swagger_types = Sinatra::SwaggerExposer::Configuration::SwaggerTypes.new
      types.each_pair do |name, param|
        swagger_types.add_type name, param
      end
      processor_creator = Sinatra::SwaggerExposer::SwaggerProcessorCreator.new(swagger_types)
      swagger_endpoint = FakeSwaggerEndpointForTestSwaggerRequestProcessorCreator.new(parameters, responses, produces)
      processor_creator.create_request_processor(swagger_endpoint)
    end

    it 'create a processor for primitive types' do
      endpoint_parameter = Sinatra::SwaggerExposer::Configuration::SwaggerEndpointParameter.new(
        'plop',
        '',
        Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_BODY,
        true,
        Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_STRING,
        {:minLength => 2},
        []
      )
      processors_dispatchers = create_request_processor({}, [endpoint_parameter]).processors_dispatchers
      processors_dispatchers.length.must_equal 1
      processors_dispatcher = processors_dispatchers[0]
      processors_dispatcher.how_to_pass.must_equal Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_BODY
      processor = processors_dispatcher.processor
      processor.must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValueProcessor
      processor.name.must_equal 'plop'
      processor.required.must_be_instance_of TrueClass
      processor.params.must_equal({:minLength => 2})
    end

    it 'transmits the produeces param' do
      create_request_processor({}, [], {}, ['image/png']).produces.must_equal ['image/png']
    end

    it 'deal with useless request processor' do
      endpoint_parameter = Sinatra::SwaggerExposer::Configuration::SwaggerEndpointParameter.new(
        'plop',
        '',
        Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_PATH,
        true,
        Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_STRING,
        {},
        []
      )
      processors_dispatchers = create_request_processor({}, [endpoint_parameter]).processors_dispatchers
      processors_dispatchers.length.must_equal 0
    end

    it 'deal with useless response processor' do
      response_processors = create_request_processor(
        {},
        [],
        {
          200 => FakeEndpointResponseForTestSwaggerRequestProcessorCreator.new(Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_FILE)
        }
      ).response_processors
      response_processors.keys.length.must_equal 1
      response_processors.keys[0].must_equal 200
      response_processors[200].must_be_nil
    end

    it 'create a processor for primitive array types' do
      endpoint_parameter = Sinatra::SwaggerExposer::Configuration::SwaggerEndpointParameter.new(
        'plop',
        '',
        Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_BODY,
        true,
        [Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_STRING],
        {:minLength => 2},
        []
      )
      processors_dispatchers = create_request_processor({}, [endpoint_parameter]).processors_dispatchers
      processors_dispatchers.length.must_equal 1
      processors_dispatcher = processors_dispatchers[0]
      processors_dispatcher.how_to_pass.must_equal Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_BODY
      processor = processors_dispatcher.processor
      processor.must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerArrayValueProcessor
      processor.required.must_be_instance_of TrueClass
      processor_for_values = processor.processor_for_values
      processor_for_values.name.must_equal 'plop'
      processor_for_values.type.must_equal 'string'
      processor_for_values.params.must_equal({:minLength => 2})
    end

    it 'create a processor for non-primitive array types' do
      endpoint_parameter = Sinatra::SwaggerExposer::Configuration::SwaggerEndpointParameter.new(
        'plop',
        '',
        Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_BODY,
        true,
        ['type_1'],
        {},
        ['type_1']
      )
      processors_dispatchers = create_request_processor(
        {
          'type_1' => {
            :properties => {
              :foo => {:type => String},
            }}
        },
        [endpoint_parameter]
      ).processors_dispatchers
      processors_dispatchers.length.must_equal 1
      processors_dispatcher = processors_dispatchers[0]
      processors_dispatcher.how_to_pass.must_equal Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_BODY
      processor = processors_dispatcher.processor
      processor.must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerArrayValueProcessor
      processor.required.must_be_instance_of TrueClass
      processor_for_values = processor.processor_for_values
      processor_for_values.name.must_equal 'plop'
      processor_for_values.attributes_processors[0].name.must_equal 'foo'
    end

    it 'create processors for types inside types' do
      endpoint_parameter = Sinatra::SwaggerExposer::Configuration::SwaggerEndpointParameter.new(
        'plop',
        '',
        Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_BODY,
        true,
        'type_3',
        {},
        ['type_3']
      )
      processors_dispatchers = create_request_processor(
        {
          'type_1' => {
            :properties => {
              :foo => {:type => String},
            }},
          'type_2' => {
            :properties => {
              :bar => {:type => [String]}
            },
            :extends => 'type_1'
          },
          'type_3' => {
            :properties => {
              :property_type_2 => {:type => 'type_2'},
              :property_type_2_array => {:type => ['type_2']}
            }
          }
        }, [endpoint_parameter]).processors_dispatchers

      processors_dispatchers.length.must_equal 1
      processors_dispatcher = processors_dispatchers[0]
      processors_dispatcher.how_to_pass.must_equal Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_BODY
      processor = processors_dispatcher.processor
      processor.must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerTypeValueProcessor
      processor.name.must_equal 'plop'
      processor.attributes_processors.length.must_equal 2
      attribute_processor_0 = processor.attributes_processors[0]
      attribute_processor_0.must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerTypeValueProcessor
      attribute_processor_0.name.must_equal 'property_type_2'
      attribute_processor_0.attributes_processors.length.must_equal 2
      attribute_processor_0.attributes_processors[0].must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerArrayValueProcessor
      attribute_processor_0.attributes_processors[0].name.must_equal 'bar'
      attribute_processor_0.attributes_processors[1].must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValueProcessor
      attribute_processor_0.attributes_processors[1].name.must_equal 'foo'

      attributes_processor_1 = processor.attributes_processors[1]
      attributes_processor_1.must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerArrayValueProcessor
      attributes_processor_1.processor_for_values.must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerTypeValueProcessor
      attributes_processor_1.processor_for_values.name.must_equal 'property_type_2_array'
      attributes_processor_1.processor_for_values.attributes_processors.length.must_equal 2
    end

    it 'create a processor for non-primitive response types' do
      response_processors = create_request_processor(
        {
          'type_1' => {
            :properties => {
              :foo => {:type => String},
            }}
        },
        [],
        {
          200 => FakeEndpointResponseForTestSwaggerRequestProcessorCreator.new('type_1')
        }
      ).response_processors

      response_processors.keys.length.must_equal 1
      response_processors.keys[0].must_equal 200
      endpoint_response = response_processors[200]
      endpoint_response.endpoint_response.type.must_equal 'type_1'
      endpoint_response.processor
      endpoint_response.processor.must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerTypeValueProcessor
      endpoint_response.processor.name.must_equal 'Response'
      endpoint_response.processor.attributes_processors.length.must_equal 1
      attribute_processor = endpoint_response.processor.attributes_processors[0]
      attribute_processor.must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValueProcessor
      attribute_processor.name.must_equal 'foo'
      attribute_processor.type.must_equal 'string'
    end

    it 'create a processor for array response types' do
      response_processors = create_request_processor(
        {
          'type_1' => {
            :properties => {
              :foo => {:type => String},
            }}
        },
        [],
        {
          200 => FakeEndpointResponseForTestSwaggerRequestProcessorCreator.new(Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_ARRAY, 'type_1')
        }
      ).response_processors

      response_processors.keys.length.must_equal 1
      response_processors.keys[0].must_equal 200
      endpoint_response = response_processors[200]
      endpoint_response.endpoint_response.type.must_equal 'array'
      endpoint_response.processor
      endpoint_response.processor.must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerArrayValueProcessor
      endpoint_response.processor.name.must_equal 'Response'
      endpoint_response.processor.processor_for_values.must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerTypeValueProcessor
      endpoint_response.processor.processor_for_values.name.must_equal 'Response'
      endpoint_response.processor.processor_for_values.attributes_processors.length.must_equal 1
      endpoint_response.processor.processor_for_values.attributes_processors[0].must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValueProcessor
      endpoint_response.processor.processor_for_values.attributes_processors[0].name.must_equal 'foo'
    end

  end

end
