require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-exposer'
require 'rack/test'

class TestSwaggerExposer < Minitest::Test

  describe Sinatra::SwaggerExposer do

    include Rack::Test::Methods
    include TestUtilities

    class MySinatraApp_Minimal < Sinatra::Base
      set :logging, true
      register Sinatra::SwaggerExposer
    end

    def app
      MySinatraApp_Minimal
    end

    it 'answer when asking for swagger' do
      get('/swagger_doc.json')
      JSON.parse(last_response.body).must_equal(
          {
              'swagger' => '2.0',
              'consumes' => ['application/json'],
              'produces' => ['application/json'],
              'paths' => {
                  '/swagger_doc.json' => {
                      'get' => {'produces' => ['application/json']},
                      'options' => {'produces' => ['application/json']}}
              }
          })
    end

    it 'answer when asking for head ' do
      options('/swagger_doc.json')
      last_response.body.must_equal('')
    end

    it 'should be able to register the module' do
      class MySinatraApp_Register < Sinatra::Base
        register Sinatra::SwaggerExposer
      end
    end

    it 'should fail after a bad description' do
      must_raise_swag_and_match(-> {
        class MySinatraApp_BadDescription < Sinatra::Base
          register Sinatra::SwaggerExposer
          endpoint_description({})
        end
      }, 'description')
    end

    it 'should fail after 2 descriptions' do
      must_raise_swag_and_match(-> {
        class MySinatraApp_2Descriptions < Sinatra::Base
          register Sinatra::SwaggerExposer
          endpoint_description 'plap'
          endpoint_description 'plop'
        end
      }, 'description')
    end

    it 'should fail after a bad summary' do
      must_raise_swag_and_match(-> {
        class MySinatraApp_BadSummary < Sinatra::Base
          register Sinatra::SwaggerExposer
          endpoint_summary({})
        end
      }, 'summary')
    end

    it 'should fail after 2 summaries' do
      must_raise_swag_and_match(-> {
        class MySinatraApp_2Summaries < Sinatra::Base
          register Sinatra::SwaggerExposer
          endpoint_summary 'plap'
          endpoint_summary 'plop'
        end
      }, 'summary')
    end

    it 'should enable to declare info' do
      class MySinatraApp_Info < Sinatra::Base
        register Sinatra::SwaggerExposer
        general_info({:version => '1.0.0'})
      end
      MySinatraApp_Info.swagger_info.must_be_instance_of Sinatra::SwaggerExposer::SwaggerInfo
      MySinatraApp_Info.swagger_info.to_swagger.must_equal({:version => '1.0.0'})
    end

    it 'should enable to declare a type' do
      class MySinatraApp_DeclareType < Sinatra::Base
        register Sinatra::SwaggerExposer
        type 'status', {}
      end
      MySinatraApp_DeclareType.swagger_types.length.must_equal 1
      MySinatraApp_DeclareType.swagger_types.keys.first.must_equal 'status'
      MySinatraApp_DeclareType.swagger_types.values.first.must_be_instance_of Sinatra::SwaggerExposer::SwaggerType
    end

    it 'should fail after 2 types with the same name' do
      must_raise_swag_and_match(-> {
        class MySinatraApp_2TypesWithSameName < Sinatra::Base
          register Sinatra::SwaggerExposer
          type 'status', {}
          type 'status', {}
        end
      }, 'status')
    end

    it 'should fail after 2 responses with the same code' do
      must_raise_swag_and_match(-> {
        class MySinatraApp_2ResponsesSameCode < Sinatra::Base
          register Sinatra::SwaggerExposer
          endpoint_response 200, 'Plop'
          endpoint_response 200, 'Plop'
        end
      }, '200')
    end

    it 'should register endpoint' do
      class MySinatraApp_RegisterEndpoint < Sinatra::Base
        register Sinatra::SwaggerExposer

        endpoint_response 200, 'Plop'
        get '/path' do
          200
        end
      end
      MySinatraApp_RegisterEndpoint.swagger_endpoints.length.must_equal 3
      MySinatraApp_RegisterEndpoint.swagger_endpoints.last.path.must_equal '/path'
      MySinatraApp_RegisterEndpoint.swagger_endpoints.last.type.must_equal 'get'
      MySinatraApp_RegisterEndpoint.swagger_endpoints.last.to_swagger.must_equal(
          {:produces => ['application/json'], :responses => {200 => {:description => 'Plop'}}}
      )
    end

    it 'should register endpoints with all methods' do
      class MySinatraApp_RegisterEndpointAllMethods < Sinatra::Base
        register Sinatra::SwaggerExposer
        delete '/path' do
          200
        end
        get '/path' do
          200
        end
        head '/path' do
          200
        end
        link '/path' do
          200
        end
        options '/path' do
          200
        end
        patch '/path' do
          200
        end
        post '/path' do
          200
        end
        put '/path' do
          200
        end
        unlink '/path' do
          200
        end
      end
      MySinatraApp_RegisterEndpointAllMethods.swagger_endpoints.length.must_equal 11
    end

  end

end
