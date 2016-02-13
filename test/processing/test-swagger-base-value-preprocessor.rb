require_relative '../minitest-helper'
require_relative '../test-utilities'

require_relative '../../lib/sinatra/swagger-exposer/processing/swagger-base-value-preprocessor'

class TestSwaggerBaseValuePreprocessor < Minitest::Test

  describe Sinatra::SwaggerExposer::Processing::SwaggerBaseValuePreprocessor do

    include TestUtilities

    class SwaggerTestingValuePreprocessor < Sinatra::SwaggerExposer::Processing::SwaggerBaseValuePreprocessor

      attr_reader :value

      def initialize(name, required, default = nil, return_value = nil)
        super(name, required, default)
        @return_value = return_value
      end

      def validate_param_value(value)
        @value = value
        @return_value
      end
    end

    class SwaggerFailingValuePreprocessor < Sinatra::SwaggerExposer::Processing::SwaggerBaseValuePreprocessor

      attr_reader :value

      def initialize(name, required, default = nil)
        super(name, required, default)
      end

      def validate_param_value(value)
        raise 'Should not be called'
      end
    end

    def new_bvp_and_run(name, required, value, default = nil)
      SwaggerTestingValuePreprocessor.new(name, required, default).process(value)
    end

    it 'should do nothing when the value is null' do
      preprocessor = SwaggerFailingValuePreprocessor.new('plop', false, nil)
      preprocessor.process({'plop' => nil}).must_equal({'plop' => nil})
      preprocessor.value.must_equal nil
    end

    it 'should fail when a param is missing' do
      must_raise_swag_and_equal(
      -> { new_bvp_and_run('plop', true, {}) },
      'Mandatory parameter [plop] is missing'
      )
    end

    it 'should fail when a param is mandatory but nil' do
      must_raise_swag_and_equal(
        -> { new_bvp_and_run('plop', true, {'plop' => nil}) },
        'Mandatory parameter [plop] is missing'
      )
    end

    it 'should add a default parameter is here' do
      new_bvp_and_run('plop', false, {}, 'a').must_equal({'plop' => 'a'})
    end

    it 'should fail when the type is wrong' do
      must_raise_swag_and_equal(
      -> { new_bvp_and_run('plop', false, 'a') },
      'Parameter [plop] should be an object but is a [String]'
      )
    end

    it 'should call the delegate implementation' do
      preprocessor = SwaggerTestingValuePreprocessor.new('plop', false, nil, 'return')
      preprocessor.process({'plop' => 'value'}).must_equal({'plop' => 'return'})
      preprocessor.value.must_equal 'value'
    end

    it 'should calculate if it is useful' do
      Sinatra::SwaggerExposer::Processing::SwaggerBaseValuePreprocessor.new('a', false).useful?.must_be_instance_of FalseClass
      Sinatra::SwaggerExposer::Processing::SwaggerBaseValuePreprocessor.new('a', true).useful?.must_be_instance_of TrueClass
      Sinatra::SwaggerExposer::Processing::SwaggerBaseValuePreprocessor.new('a', false, 'a').useful?.must_be_instance_of TrueClass
      Sinatra::SwaggerExposer::Processing::SwaggerBaseValuePreprocessor.new('a', true, 'a').useful?.must_be_instance_of TrueClass
    end

  end

end
