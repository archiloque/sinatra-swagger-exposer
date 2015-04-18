require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-endpoint-parameter'
require_relative '../lib/sinatra/swagger-exposer/swagger-parameter-preprocessor'

class TestSwaggerEndpoint < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerParameterPreprocessor do

    include TestUtilities

    TYPE_BOOLEAN = Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_BOOLEAN
    TYPE_DATE_TIME = Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_DATE_TIME
    TYPE_INTEGER = Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_INTEGER
    TYPE_NUMBER = Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_NUMBER
    TYPE_STRING = Sinatra::SwaggerExposer::SwaggerParameterHelper::TYPE_STRING

    def new_pp(name, how_to_pass, required, type, default, params = {})
      Sinatra::SwaggerExposer::SwaggerParameterPreprocessor.new(name, how_to_pass, required, type, default, params)
    end

    def new_pp_and_run(name, how_to_pass, required, type, default, app_params, app_headers, parsed_body, preprocessor_params = {})
      new_pp(name, how_to_pass, required, type, default, preprocessor_params).run(FakeParameterPreprocessorApp.new(app_params, app_headers), parsed_body)
    end

    class FakeParameterPreprocessorApp

      attr_reader :params, :headers

      def initialize(params, header)
        @params = params
        @headers = header
      end

    end

    it 'should calculate if the processor is useful' do
      new_pp('plop', 'query', true, TYPE_STRING, nil).useful?.must_be_instance_of TrueClass
      new_pp('plop', 'query', true, TYPE_NUMBER, nil).useful?.must_be_instance_of TrueClass
      new_pp('plop', 'query', true, TYPE_BOOLEAN, nil).useful?.must_be_instance_of TrueClass
      new_pp('plop', 'query', true, TYPE_INTEGER, nil).useful?.must_be_instance_of TrueClass

      new_pp('plop', 'query', false, TYPE_STRING, '').useful?.must_be_instance_of TrueClass
      new_pp('plop', 'query', false, TYPE_NUMBER, 12).useful?.must_be_instance_of TrueClass
      new_pp('plop', 'query', false, TYPE_BOOLEAN, true).useful?.must_be_instance_of TrueClass
      new_pp('plop', 'query', false, TYPE_INTEGER, 10).useful?.must_be_instance_of TrueClass

      new_pp('plop', 'query', false, TYPE_STRING, nil).useful?.must_be_instance_of FalseClass
      new_pp('plop', 'query', false, TYPE_NUMBER, nil).useful?.must_be_instance_of TrueClass
      new_pp('plop', 'query', false, TYPE_BOOLEAN, nil).useful?.must_be_instance_of TrueClass
      new_pp('plop', 'query', false, TYPE_INTEGER, nil).useful?.must_be_instance_of TrueClass
    end

    it 'should fail when a param is missing in all possibles places' do
      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'query', true, TYPE_STRING, {}, {}, {}, {}) },
      'Mandatory parameter [plop] is missing'
      )
      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'header', true, TYPE_STRING, {}, {}, {}, {}) },
      'Mandatory parameter [PLOP] is missing'
      )
      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'body', true, TYPE_STRING, {}, {}, {}, {}) },
      'Mandatory parameter [plop] is missing'
      )
    end

    it 'should fail when a param has the wrong type in all possibles places' do
      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, {'plop' => 'a'}, {}, {}) },
      'Parameter [plop] should be an integer but is [a]'
      )
      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'header', true, TYPE_INTEGER, {}, {}, {'PLOP' => 'a'}, {}) },
      'Parameter [PLOP] should be an integer but is [a]'
      )
      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'body', true, TYPE_INTEGER, {}, {}, {}, {'plop' => 'a'}) },
      'Parameter [plop] should be an integer but is [a]'
      )
    end

    it 'should be ok when a parameter is here in all possibles places' do
      new_pp_and_run('plop', 'query', true, TYPE_STRING, {}, {'plop' => 'a'}, {}, {}).must_equal({'plop' => 'a'})
      new_pp_and_run('plop', 'header', true, TYPE_STRING, {}, {}, {'PLOP' => 'a'}, {}).must_equal({'PLOP' => 'a'})
      new_pp_and_run('plop', 'body', true, TYPE_STRING, {}, {}, {}, {'plop' => 'a'}).must_equal({'plop' => 'a'})
    end

    it 'should add a default parameter is here in all possibles places' do
      app_params = {}
      new_pp_and_run('plop', 'query', false, TYPE_STRING, 'a', app_params, {}, {})
      app_params['plop'].must_equal 'a'

      headers_params = {}
      new_pp_and_run('plop', 'header', false, TYPE_STRING, 'a', {}, headers_params, {})
      headers_params['PLOP'].must_equal 'a'

      body_content = {}
      new_pp_and_run('plop', 'body', false, TYPE_STRING, 'a', {}, {}, body_content)
      body_content['plop'].must_equal 'a'
    end

    it 'should validate the params type for integers' do
      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, {'plop' => 'a'}, {}, {}) },
      'Parameter [plop] should be an integer but is [a]'
      )

      params = {'plop' => '123'}
      new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, params, {}, {})
      params['plop'].must_equal 123

      params = {'plop' => '123'}
      new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, params, {}, {})
      params['plop'].must_equal 123

      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, {'plop' => 123.45}, {}, {}) },
      'Parameter [plop] should be an integer but is [123.45]'
      )
      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, {'plop' => true}, {}, {}) },
      'Parameter [plop] should be an integer but is [true]'
      )
    end

    it 'should validate the params type for numbers' do
      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'query', true, TYPE_NUMBER, {}, {'plop' => 'a'}, {}, {}) },
      'Parameter [plop] should be a float but is [a]'
      )

      new_pp_and_run('plop', 'query', true, TYPE_NUMBER, {}, {'plop' => 123}, {}, {})

      params = {'plop' => 123.45}
      new_pp_and_run('plop', 'query', true, TYPE_NUMBER, {}, params, {}, {})
      params['plop'].must_equal 123.45

      params = {'plop' => '123.45'}
      new_pp_and_run('plop', 'query', true, TYPE_NUMBER, {}, params, {}, {})
      params['plop'].must_equal 123.45

      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'query', true, TYPE_NUMBER, {}, {'plop' => true}, {}, {}) },
      'Parameter [plop] should be a float but is [true]'
      )
    end

    it 'should validate the params type for boolean' do
      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'query', true, TYPE_BOOLEAN, {}, {'plop' => 'a'}, {}, {}) },
      'Parameter [plop] should be an boolean but is [a]'
      )
      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'query', true, TYPE_BOOLEAN, {}, {'plop' => 123}, {}, {}) },
      'Parameter [plop] should be an boolean but is [123]'
      )
      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'query', true, TYPE_BOOLEAN, {}, {'plop' => 123.45}, {}, {}) },
      'Parameter [plop] should be an boolean but is [123.45]'
      )

      params = {'plop' => true}
      new_pp_and_run('plop', 'query', true, TYPE_BOOLEAN, {}, params, {}, {})
      params['plop'].must_be_instance_of TrueClass

      params = {'plop' => 'true'}
      new_pp_and_run('plop', 'query', true, TYPE_BOOLEAN, {}, params, {}, {})
      params['plop'].must_be_instance_of TrueClass

      params = {'plop' => false}
      new_pp_and_run('plop', 'query', true, TYPE_BOOLEAN, {}, params, {}, {})
      params['plop'].must_be_instance_of FalseClass

      params = {'plop' => 'false'}
      new_pp_and_run('plop', 'query', true, TYPE_BOOLEAN, {}, params, {}, {})
      params['plop'].must_be_instance_of FalseClass
    end

    it 'should validate the params type for date time' do
      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'query', true, TYPE_DATE_TIME, {}, {'plop' => 'a'}, {}, {}) },
      'Parameter [plop] should be a date time but is [a]'
      )

      params = {'plop' => '2001-02-03T04:05:06+07:00'}
      new_pp_and_run('plop', 'query', true, TYPE_DATE_TIME, {}, params, {}, {})
      params['plop'].must_equal DateTime.rfc3339('2001-02-03T04:05:06+07:00')
    end

  def validate_param_value(name, exclusive_name, ok_value, non_ok_value, comparison)
      new_pp_and_run('plop', 'query', false, TYPE_INTEGER, {}, {}, {}, {}, {name => 2})

      new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, {'plop' => 2}, {}, {}, {name => 2})
      new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, {'plop' => 2}, {}, {}, {name => 2, exclusive_name => false})
      new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, {'plop' => 2}, {}, {}, {name => ok_value, exclusive_name => true})

      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, {'plop' => 2}, {}, {}, {name => non_ok_value}) },
      "Parameter [plop] should be #{comparison}= than [#{non_ok_value}] but is [2]"
      )
      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, {'plop' => 2}, {}, {}, {name => 2, exclusive_name => true}) },
      "Parameter [plop] should be #{comparison} than [2] but is [2]"
      )
    end

    it 'should validate the params value' do
      validate_param_value(:minimum, :exclusiveMinimum, 1, 3, '>')
      validate_param_value(:maximum, :exclusiveMaximum, 3, 1, '<')
    end

    def validate_param_length(name, ok_value, non_ok_value, comparison)
      new_pp_and_run('plop', 'query', false, TYPE_STRING, {}, {}, {}, {}, {name => 2})

      new_pp_and_run('plop', 'query', true, TYPE_STRING, {}, {'plop' => 'ab'}, {}, {}, {name => 2})
      new_pp_and_run('plop', 'query', true, TYPE_STRING, {}, {'plop' => 'ab'}, {}, {}, {name => ok_value})

      must_raise_swag_and_equal(
      -> { new_pp_and_run('plop', 'query', true, TYPE_STRING, {}, {'plop' => 'ab'}, {}, {}, {name => non_ok_value}) },
      "Parameter [plop] length should be #{comparison}= than #{non_ok_value} but is 2 for [ab]"
      )
    end

    it 'should validate the params length' do
      validate_param_length(:minLength, 1, 3, '>')
      validate_param_length(:maxLength, 3, 1, '<')
    end

  end

end
