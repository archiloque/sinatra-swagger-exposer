require_relative '../minitest-helper'
require_relative '../test-utilities'

require_relative '../../lib/sinatra/swagger-exposer/processing/swagger-type-value-preprocessor'

class TestSwaggerTypeValuePreprocessor < Minitest::Test

  describe Sinatra::SwaggerExposer::Processing::SwaggerTypeValuePreprocessor do

    include TestUtilities

    class PreprocessorForTypeTests

      attr_reader :value

      def initialize(key, replacement)
        @key = key
        @replacement = replacement
      end

      def process(value)
        value[@key] = @replacement
      end

    end

    def new_tvp(name, attributes_preprocessors)
      Sinatra::SwaggerExposer::Processing::SwaggerTypeValuePreprocessor.new(name, false, attributes_preprocessors)
    end

    def new_tvp_and_run(name, attributes_preprocessors, value)
      type_value_preprocessor = new_tvp(name, attributes_preprocessors)
      type_value_preprocessor.validate_param_value(value)
    end

    it 'should calculate if the processor is useful' do
      new_tvp('plop', []).useful?.must_be_instance_of FalseClass
      new_tvp('plop', ['']).useful?.must_be_instance_of TrueClass
    end

    it 'should process the preprocessors' do
      preprocessor_for_test1 = PreprocessorForTypeTests.new('a', 1)
      preprocessor_for_test2 = PreprocessorForTypeTests.new('b', 2)
      new_tvp_and_run('plop', [preprocessor_for_test1, preprocessor_for_test2], {'a' => 0, 'b' => 0}).must_equal({'a' => 1, 'b' => 2})
    end


  end

end
