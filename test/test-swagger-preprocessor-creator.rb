require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-preprocessor-creator'
require_relative '../lib/sinatra/swagger-exposer/configuration/swagger-types'

class TestSwaggerPreprocessorCreator < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerPreprocessorCreator do

    include TestUtilities

    class FakeSwaggerEndpointForTestSwaggerPreprocessorCreator

      attr_reader :parameters

      def initialize(parameters)
        @parameters = parameters
      end

    end

    def create_endpoint_processor(types, parameters)
      swagger_types = Sinatra::SwaggerExposer::Configuration::SwaggerTypes.new
      types.each_pair do |name, param|
        swagger_types.add_type name, param
      end
      preprocessor_creator = Sinatra::SwaggerExposer::SwaggerPreprocessorCreator.new(swagger_types)
      swagger_endpoint = FakeSwaggerEndpointForTestSwaggerPreprocessorCreator.new(parameters)
      preprocessor_creator.create_endpoint_processor(swagger_endpoint).preprocessors_dispatchers
    end

    it 'create a preprocessor for primitive types' do
      endpoint_parameter = Sinatra::SwaggerExposer::Configuration::SwaggerEndpointParameter.new(
          'plop',
          '',
          Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_BODY,
          true,
          Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_STRING,
          {:minLength => 2},
          []
      )
      preprocessors_dispatchers = create_endpoint_processor({}, [endpoint_parameter])
      preprocessors_dispatchers.length.must_equal 1
      preprocessors_dispatcher = preprocessors_dispatchers[0]
      preprocessors_dispatcher.how_to_pass.must_equal Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_BODY
      preprocessor = preprocessors_dispatcher.preprocessor
      preprocessor.must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValuePreprocessor
      preprocessor.name.must_equal 'plop'
      preprocessor.required.must_be_instance_of TrueClass
      preprocessor.params.must_equal({:minLength => 2})
    end

    it 'deal with useless preprocessor' do
      endpoint_parameter = Sinatra::SwaggerExposer::Configuration::SwaggerEndpointParameter.new(
          'plop',
          '',
          Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_PATH,
          true,
          Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_STRING,
          {},
          []
      )
      preprocessors_dispatchers = create_endpoint_processor({}, [endpoint_parameter])
      preprocessors_dispatchers.length.must_equal 0
    end

    it 'create a preprocessor for primitive array types' do
      endpoint_parameter = Sinatra::SwaggerExposer::Configuration::SwaggerEndpointParameter.new(
          'plop',
          '',
          Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_BODY,
          true,
          [Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_STRING],
          {:minLength => 2},
          []
      )
      preprocessors_dispatchers = create_endpoint_processor({}, [endpoint_parameter])
      preprocessors_dispatchers.length.must_equal 1
      preprocessors_dispatcher = preprocessors_dispatchers[0]
      preprocessors_dispatcher.how_to_pass.must_equal Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_BODY
      preprocessor = preprocessors_dispatcher.preprocessor
      preprocessor.must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerArrayValuePreprocessor
      preprocessor.required.must_be_instance_of TrueClass
      preprocessor_for_values = preprocessor.preprocessor_for_values
      preprocessor_for_values.name.must_equal 'plop'
      preprocessor_for_values.params.must_equal({:minLength => 2})
    end

    it 'create preprocessors for types inside types' do
      endpoint_parameter = Sinatra::SwaggerExposer::Configuration::SwaggerEndpointParameter.new(
          'plop',
          '',
          Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_BODY,
          true,
          'type_3',
          {},
          ['type_3']
      )
      preprocessors_dispatchers = create_endpoint_processor(
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
          }, [endpoint_parameter])

      preprocessors_dispatchers.length.must_equal 1
      preprocessors_dispatcher = preprocessors_dispatchers[0]
      preprocessors_dispatcher.how_to_pass.must_equal Sinatra::SwaggerExposer::SwaggerParameterHelper::HOW_TO_PASS_BODY
      preprocessor = preprocessors_dispatcher.preprocessor
      preprocessor.must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerTypeValuePreprocessor
      preprocessor.name.must_equal 'plop'
      preprocessor.attributes_preprocessors.length.must_equal 2
      preprocessor.attributes_preprocessors[0].must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerTypeValuePreprocessor
      preprocessor.attributes_preprocessors[0].name.must_equal 'property_type_2'
      preprocessor.attributes_preprocessors[0].attributes_preprocessors.length.must_equal 2
      preprocessor.attributes_preprocessors[0].attributes_preprocessors[0].must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerArrayValuePreprocessor
      preprocessor.attributes_preprocessors[0].attributes_preprocessors[0].name.must_equal 'bar'
      preprocessor.attributes_preprocessors[0].attributes_preprocessors[1].must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValuePreprocessor
      preprocessor.attributes_preprocessors[0].attributes_preprocessors[1].name.must_equal 'foo'

      preprocessor.attributes_preprocessors[1].must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerArrayValuePreprocessor
      preprocessor.attributes_preprocessors[1].preprocessor_for_values.must_be_instance_of Sinatra::SwaggerExposer::Processing::SwaggerTypeValuePreprocessor
      preprocessor.attributes_preprocessors[1].preprocessor_for_values.name.must_equal 'property_type_2_array'
      preprocessor.attributes_preprocessors[1].preprocessor_for_values.attributes_preprocessors.length.must_equal 2
    end

  end

end
