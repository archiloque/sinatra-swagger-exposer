require_relative '../minitest-helper'
require_relative '../test-utilities'

require_relative '../../lib/sinatra/swagger-exposer/processing/swagger-array-value-preprocessor'

class TestSwaggerArrayValuePreprocessor < Minitest::Test

  describe Sinatra::SwaggerExposer::Processing::SwaggerArrayValuePreprocessor do

    include TestUtilities

    class PreprocessorForArrayTests

      attr_reader :values

      def initialize(responses)
        @responses = responses
        @values = []
        @response_index = 0
      end

      def validate_param_value(value)
        @values << value
        result = @responses[@response_index]
        @response_index += 1
        result
      end

    end

    def new_avp(name, preprocessor_for_values)
      Sinatra::SwaggerExposer::Processing::SwaggerArrayValuePreprocessor.new(name, false, preprocessor_for_values)
    end

    def new_avp_and_run(name, preprocessor_for_values, value)
      array_value_preprocessor = new_avp(name, preprocessor_for_values)
      array_value_preprocessor.validate_param_value(value)
    end

    it 'should be useful' do
      new_avp('plop', nil).useful?.must_equal true
    end

    it 'should fail if the value is not an array' do
      must_raise_swag_and_equal(
      -> { new_avp_and_run('plop', nil, 'ah') },
      'Parameter [plop] should be an array but is [ah]'
      )
    end

    it 'should iterate on the array' do
      preprocessor = PreprocessorForArrayTests.new(['a', 'b'])
      new_avp_and_run('name', preprocessor, [1, 2]).must_equal(['a', 'b'])
      preprocessor.values.must_equal [1, 2]
    end

  end

end
