require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-endpoint-parameter'
require_relative '../lib/sinatra/swagger-exposer/swagger-parameter-preprocessor'

class TestSwaggerEndpoint < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerParameterPreprocessor do

    include TestUtilities

    TYPE_STRING = Sinatra::SwaggerExposer::SwaggerEndpointParameter::TYPE_STRING
    TYPE_INTEGER = Sinatra::SwaggerExposer::SwaggerEndpointParameter::TYPE_INTEGER
    TYPE_NUMBER = Sinatra::SwaggerExposer::SwaggerEndpointParameter::TYPE_NUMBER
    TYPE_BOOLEAN = Sinatra::SwaggerExposer::SwaggerEndpointParameter::TYPE_BOOLEAN


    def new_pp(name, how_to_pass, required, type, default)
      Sinatra::SwaggerExposer::SwaggerParameterPreprocessor.new(name, how_to_pass, required, type, default)
    end

    def new_pp_and_run(name, how_to_pass, required, type, default, app_params, app_headers, parsed_body)
      new_pp(name, how_to_pass, required, type, default).run(FakeParameterPreprocessorApp.new(app_params, app_headers), parsed_body)
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
      must_raise_swag_and_match(-> { new_pp_and_run('plop', 'query', true, TYPE_STRING, {}, {}, {}, {}) }, /#{'plop'}/)
      must_raise_swag_and_match(-> { new_pp_and_run('plop', 'header', true, TYPE_STRING, {}, {}, {}, {}) }, /#{'PLOP'}/)
      must_raise_swag_and_match(-> { new_pp_and_run('plop', 'body', true, TYPE_STRING, {}, {}, {}, {}) }, /#{'plop'}/)
    end

    it 'should fail when a param has the wrong type in all possibles places' do
      must_raise_swag_and_match(-> { new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, {'plop' => 'a'}, {}, {}) }, /#{'integer'}/)
      must_raise_swag_and_match(-> { new_pp_and_run('plop', 'header', true, TYPE_INTEGER, {}, {}, {'PLOP' => 'a'}, {}) }, /#{'integer'}/)
      must_raise_swag_and_match(-> { new_pp_and_run('plop', 'body', true, TYPE_INTEGER, {}, {}, {}, {'plop' => 'a'}) }, /#{'integer'}/)
    end

    it 'should be ok when a parameter is here in all possibles places' do
      new_pp_and_run('plop', 'query', true, TYPE_STRING, {}, {'plop' => 'a'}, {}, {})
      new_pp_and_run('plop', 'header', true, TYPE_STRING, {}, {}, {'PLOP' => 'a'}, {})
      new_pp_and_run('plop', 'body', true, TYPE_STRING, {}, {}, {}, {'plop' => 'a'})
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

    it 'should validate the params' do
      int = Sinatra::SwaggerExposer::SwaggerEndpointParameter::TYPE_INTEGER
      must_raise_swag_and_match(-> { new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, {'plop' => 'a'}, {}, {}) }, /#{'integer'}/)

      params = {'plop' => '123'}
      new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, params, {}, {})
      params['plop'].must_equal 123

      params = {'plop' => '123'}
      new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, params, {}, {})
      params['plop'].must_equal 123

      must_raise_swag_and_match(-> { new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, {'plop' => 123.45}, {}, {}) }, /#{'integer'}/)
      must_raise_swag_and_match(-> { new_pp_and_run('plop', 'query', true, TYPE_INTEGER, {}, {'plop' => true}, {}, {}) }, /#{'integer'}/)

      must_raise_swag_and_match(-> { new_pp_and_run('plop', 'query', true, TYPE_NUMBER, {}, {'plop' => 'a'}, {}, {}) }, /#{'float'}/)
      new_pp_and_run('plop', 'query', true, TYPE_NUMBER, {}, {'plop' => 123}, {}, {})

      params = {'plop' => 123.45}
      new_pp_and_run('plop', 'query', true, TYPE_NUMBER, {}, params, {}, {})
      params['plop'].must_equal 123.45

      params = {'plop' => '123.45'}
      new_pp_and_run('plop', 'query', true, TYPE_NUMBER, {}, params, {}, {})
      params['plop'].must_equal 123.45

      must_raise_swag_and_match(-> { new_pp_and_run('plop', 'query', true, TYPE_NUMBER, {}, {'plop' => true}, {}, {}) }, /#{'float'}/)

      must_raise_swag_and_match(-> { new_pp_and_run('plop', 'query', true, TYPE_BOOLEAN, {}, {'plop' => 'a'}, {}, {}) }, /#{'boolean'}/)
      must_raise_swag_and_match(-> { new_pp_and_run('plop', 'query', true, TYPE_BOOLEAN, {}, {'plop' => 123}, {}, {}) }, /#{'boolean'}/)
      must_raise_swag_and_match(-> { new_pp_and_run('plop', 'query', true, TYPE_BOOLEAN, {}, {'plop' => 123.45}, {}, {}) }, /#{'boolean'}/)

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

  end

end
