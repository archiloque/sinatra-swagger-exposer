require_relative '../minitest-helper'
require_relative '../test-utilities'

require_relative '../../lib/sinatra/swagger-exposer/processing/swagger-base-value-processor'

class TestSwaggerBaseValueProcessor < Minitest::Test

  describe Sinatra::SwaggerExposer::Processing::SwaggerBaseValueProcessor do

    include TestUtilities

    class SwaggerTestingValueProcessor < Sinatra::SwaggerExposer::Processing::SwaggerBaseValueProcessor

      attr_reader :value

      def initialize(name, required, default = nil, return_value = nil)
        super(name, required, default)
        @return_value = return_value
      end

      def validate_value(value)
        @value = value
        @return_value
      end
    end

    class SwaggerFailingValueprocessor < Sinatra::SwaggerExposer::Processing::SwaggerBaseValueProcessor

      attr_reader :value

      def initialize(name, required, default = nil)
        super(name, required, default)
      end

      def validate_param_value(value)
        raise 'Should not be called'
      end
    end

    def new_bvp_and_run(name, required, value, default = nil)
      SwaggerTestingValueProcessor.new(name, required, default).process(value)
    end

    it 'should do nothing when the value is null' do
      processor = SwaggerFailingValueprocessor.new('plop', false, nil)
      processor.process({'plop' => nil}).must_equal({'plop' => nil})
      processor.value.must_equal nil
    end

    it 'should fail when a param is missing' do
      must_raise_swag_and_equal(
        -> { new_bvp_and_run('plop', true, {}) },
        'Mandatory value [plop] is missing'
      )
    end

    it 'should fail when a param is mandatory but nil' do
      must_raise_swag_and_equal(
        -> { new_bvp_and_run('plop', true, {'plop' => nil}) },
        'Mandatory value [plop] is missing'
      )
    end

    it 'should add a default parameter is here' do
      new_bvp_and_run('plop', false, {}, 'a').must_equal({'plop' => 'a'})
    end

    it 'should fail when the type is wrong' do
      must_raise_swag_and_equal(
        -> { new_bvp_and_run('plop', false, 'a') },
        'Value [plop] should be an object but is a [String]'
      )
    end

    it 'should call the delegate implementation' do
      processor = SwaggerTestingValueProcessor.new('plop', false, nil, 'return')
      processor.process({'plop' => 'value'}).must_equal({'plop' => 'return'})
      processor.value.must_equal 'value'
    end

    it 'should calculate if it is useful' do
      Sinatra::SwaggerExposer::Processing::SwaggerBaseValueProcessor.new('a', false, nil).useful?.must_be_instance_of FalseClass
      Sinatra::SwaggerExposer::Processing::SwaggerBaseValueProcessor.new('a', true, nil).useful?.must_be_instance_of TrueClass
      Sinatra::SwaggerExposer::Processing::SwaggerBaseValueProcessor.new('a', false, 'a').useful?.must_be_instance_of TrueClass
      Sinatra::SwaggerExposer::Processing::SwaggerBaseValueProcessor.new('a', true, 'a').useful?.must_be_instance_of TrueClass
    end

  end

end
