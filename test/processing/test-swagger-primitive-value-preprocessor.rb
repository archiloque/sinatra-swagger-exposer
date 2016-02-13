require_relative '../minitest-helper'
require_relative '../test-utilities'

require_relative '../../lib/sinatra/swagger-exposer/processing/swagger-primitive-value-preprocessor'

class TestSwaggerPrimitiveValuePreprocessor < Minitest::Test

  describe Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValuePreprocessor do

    include TestUtilities

    TYPE_BOOLEAN = Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_BOOLEAN
    TYPE_DATE_TIME = Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_DATE_TIME
    TYPE_INTEGER = Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_INTEGER
    TYPE_NUMBER = Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_NUMBER
    TYPE_STRING = Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_STRING

    def new_pvp(name, type, params = {})
      Sinatra::SwaggerExposer::Processing::SwaggerPrimitiveValuePreprocessor.new(name, false, type, nil, params)
    end

    def new_pvp_and_run(name, type, values, preprocessor_params = {})
      primitive_value_preprocessor = new_pvp(name, type, preprocessor_params)
      primitive_value_preprocessor.validate_param_value(values)
    end

    it 'should calculate if the processor is useful' do
      new_pvp('plop', TYPE_STRING).useful?.must_be_instance_of FalseClass
      new_pvp('plop', TYPE_NUMBER).useful?.must_be_instance_of TrueClass
      new_pvp('plop', TYPE_INTEGER).useful?.must_be_instance_of TrueClass
      new_pvp('plop', TYPE_BOOLEAN).useful?.must_be_instance_of TrueClass
      new_pvp('plop', TYPE_DATE_TIME).useful?.must_be_instance_of TrueClass

      new_pvp('plop', TYPE_STRING, {Sinatra::SwaggerExposer::SwaggerParameterHelper::PARAMS_MIN_LENGTH => 2}).useful?.must_be_instance_of TrueClass
      new_pvp('plop', TYPE_STRING, {Sinatra::SwaggerExposer::SwaggerParameterHelper::PARAMS_MAX_LENGTH => 2}).useful?.must_be_instance_of TrueClass
    end

    it 'should fail when a param has the wrong type' do
      must_raise_swag_and_equal(
        -> { new_pvp_and_run('plop', TYPE_INTEGER, 'a', {}) },
        'Parameter [plop] should be an integer but is [a]'
      )
    end

    it 'should be ok when a parameter is here' do
      new_pvp_and_run('plop', TYPE_STRING, 'a').must_equal('a')
    end

    it 'should validate the params type for integers' do
      must_raise_swag_and_equal(
        -> { new_pvp_and_run('plop', TYPE_INTEGER, 'a') },
        'Parameter [plop] should be an integer but is [a]'
      )

      new_pvp_and_run('plop', TYPE_INTEGER, '123').must_equal 123

      must_raise_swag_and_equal(
        -> { new_pvp_and_run('plop', TYPE_INTEGER, 123.45) },
        'Parameter [plop] should be an integer but is [123.45]'
      )
      must_raise_swag_and_equal(
        -> { new_pvp_and_run('plop', TYPE_INTEGER, true) },
        'Parameter [plop] should be an integer but is [true]'
      )
    end

    it 'should validate the params type for numbers' do
      must_raise_swag_and_equal(
        -> { new_pvp_and_run('plop', TYPE_NUMBER, 'a') },
        'Parameter [plop] should be a float but is [a]'
      )

      new_pvp_and_run('plop', TYPE_NUMBER, 123).must_equal 123

      new_pvp_and_run('plop', TYPE_NUMBER, 123.45).must_equal 123.45

      new_pvp_and_run('plop', TYPE_NUMBER, '123.45').must_equal 123.45

      must_raise_swag_and_equal(
        -> { new_pvp_and_run('plop', TYPE_NUMBER, true) },
        'Parameter [plop] should be a float but is [true]'
      )
    end

    it 'should validate the params type for boolean' do
      must_raise_swag_and_equal(
        -> { new_pvp_and_run('plop', TYPE_BOOLEAN, 'a') },
        'Parameter [plop] should be an boolean but is [a]'
      )
      must_raise_swag_and_equal(
        -> { new_pvp_and_run('plop', TYPE_BOOLEAN, 123) },
        'Parameter [plop] should be an boolean but is [123]'
      )
      must_raise_swag_and_equal(
        -> { new_pvp_and_run('plop', TYPE_BOOLEAN, 123.45) },
        'Parameter [plop] should be an boolean but is [123.45]'
      )

      new_pvp_and_run('plop', TYPE_BOOLEAN, true).must_be_instance_of TrueClass

      new_pvp_and_run('plop', TYPE_BOOLEAN, 'true').must_be_instance_of TrueClass

      new_pvp_and_run('plop', TYPE_BOOLEAN, false).must_be_instance_of FalseClass

      new_pvp_and_run('plop', TYPE_BOOLEAN, 'false').must_be_instance_of FalseClass
    end

    it 'should validate the params type for date time' do
      must_raise_swag_and_equal(
        -> { new_pvp_and_run('plop', TYPE_DATE_TIME, 'a') },
        'Parameter [plop] should be a date time but is [a]'
      )

      new_pvp_and_run('plop', TYPE_DATE_TIME, '2001-02-03T04:05:06+07:00').must_equal DateTime.rfc3339('2001-02-03T04:05:06+07:00')
    end

    def validate_param_value(name, exclusive_name, ok_value, non_ok_value, comparison)
      new_pvp_and_run('plop', TYPE_INTEGER, 2, {name => 2}).must_equal 2
      new_pvp_and_run('plop', TYPE_INTEGER, 2, {name => 2, exclusive_name => false}).must_equal 2
      new_pvp_and_run('plop', TYPE_INTEGER, 2, {name => ok_value, exclusive_name => true}).must_equal 2

      must_raise_swag_and_equal(
        -> { new_pvp_and_run('plop', TYPE_INTEGER, 2, {name => non_ok_value}) },
        "Parameter [plop] should be #{comparison}= than [#{non_ok_value}] but is [2]"
      )
      must_raise_swag_and_equal(
        -> { new_pvp_and_run('plop', TYPE_INTEGER, 2, {name => 2, exclusive_name => true}) },
        "Parameter [plop] should be #{comparison} than [2] but is [2]"
      )
    end

    it 'should validate the params value' do
      validate_param_value(:minimum, :exclusiveMinimum, 1, 3, '>')
      validate_param_value(:maximum, :exclusiveMaximum, 3, 1, '<')
    end

    def validate_param_length(name, ok_value, non_ok_value, comparison)
      new_pvp_and_run('plop', TYPE_STRING, 'ab', {name => 2}).must_equal 'ab'
      new_pvp_and_run('plop', TYPE_STRING, 'ab', {name => ok_value}).must_equal 'ab'

      must_raise_swag_and_equal(
        -> { new_pvp_and_run('plop', TYPE_STRING, 'ab', {name => non_ok_value}) },
        "Parameter [plop] length should be #{comparison}= than #{non_ok_value} but is 2 for [ab]"
      )
    end

    it 'should validate the params length' do
      validate_param_length(:minLength, 1, 3, '>')
      validate_param_length(:maxLength, 3, 1, '<')
    end

  end

end
