require_relative '../minitest-helper'
require_relative '../test-utilities'

require_relative '../../lib/sinatra/swagger-exposer/processing/swagger-array-value-processor'

class TestSwaggerArrayValueProcessor < Minitest::Test

  describe Sinatra::SwaggerExposer::Processing::SwaggerArrayValueProcessor do

    include TestUtilities

    class ProcessorForArrayTests

      attr_reader :values

      def initialize(responses)
        @responses = responses
        @values = []
        @response_index = 0
      end

      def validate_value(value)
        @values << value
        result = @responses[@response_index]
        @response_index += 1
        result
      end

    end

    def new_avp(name, processor_for_values)
      Sinatra::SwaggerExposer::Processing::SwaggerArrayValueProcessor.new(name, false, processor_for_values)
    end

    def new_avp_and_run(name, processor_for_values, value)
      array_value_processor = new_avp(name, processor_for_values)
      array_value_processor.validate_value(value)
    end

    it 'should be useful' do
      new_avp('plop', nil).useful?.must_equal true
    end

    it 'should fail if the value is not an array' do
      must_raise_swag_and_equal(
        -> { new_avp_and_run('plop', nil, 'ah') },
        'Value [plop] should be an array but is [ah]'
      )
    end

    it 'should iterate on the array' do
      processor = ProcessorForArrayTests.new(['a', 'b'])
      new_avp_and_run('name', processor, [1, 2]).must_equal(['a', 'b'])
      processor.values.must_equal [1, 2]
    end

  end

end
