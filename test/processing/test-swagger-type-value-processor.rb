require_relative '../minitest-helper'
require_relative '../test-utilities'

require_relative '../../lib/sinatra/swagger-exposer/processing/swagger-type-value-processor'

class TestSwaggerTypeValueProcessor < Minitest::Test

  describe Sinatra::SwaggerExposer::Processing::SwaggerTypeValueProcessor do

    include TestUtilities

    class ProcessorForTypeTestsForTestSwaggerTypeValueProcessor

      attr_reader :value

      def initialize(key, replacement)
        @key = key
        @replacement = replacement
      end

      def process(value)
        value[@key] = @replacement
      end

    end

    def new_tvp(name, attributes_processors)
      Sinatra::SwaggerExposer::Processing::SwaggerTypeValueProcessor.new(name, false, attributes_processors)
    end

    def new_tvp_and_run(name, attributes_processors, value)
      type_value_processor = new_tvp(name, attributes_processors)
      type_value_processor.validate_value(value)
    end

    it 'should calculate if the processor is useful' do
      new_tvp('plop', []).useful?.must_be_instance_of FalseClass
      new_tvp('plop', ['']).useful?.must_be_instance_of TrueClass
    end

    it 'should process the processors' do
      processor_for_test1 = ProcessorForTypeTestsForTestSwaggerTypeValueProcessor.new('a', 1)
      processor_for_test2 = ProcessorForTypeTestsForTestSwaggerTypeValueProcessor.new('b', 2)
      new_tvp_and_run('plop', [processor_for_test1, processor_for_test2], {'a' => 0, 'b' => 0}).must_equal({'a' => 1, 'b' => 2})
    end


  end

end
