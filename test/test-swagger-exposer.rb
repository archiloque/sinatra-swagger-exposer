require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-exposer'
require 'rack/test'

# Patch rack-test to add support for link and unlink
module Rack
  module Test
    module Methods
      def_delegators :current_session, :link, :unlink
    end

    class Session
      def link(uri, params = {}, env = {}, &block)
        env = env_for(uri, env.merge(:method => 'LINK', :params => params))
        process_request(uri, env, &block)
      end

      def unlink(uri, params = {}, env = {}, &block)
        env = env_for(uri, env.merge(:method => 'UNLINK', :params => params))
        process_request(uri, env, &block)
      end
    end
  end
end

class TestSwaggerExposer < Minitest::Test

  describe Sinatra::SwaggerExposer do

    include Rack::Test::Methods
    include TestUtilities

    def MySinatraMinimalResponse
      def header
        {}
      end
    end

    class MySinatraApp_Minimal < Sinatra::Base
      set :logging, true
      register Sinatra::SwaggerExposer

      def endpoint_response
        MySinatraMinimalResponse.new
      end
    end

    def app
      @my_app
    end

    it 'answer when asking for swagger' do
      @my_app = MySinatraApp_Minimal
      get('/swagger_doc.json')
      JSON.parse(last_response.body).must_equal(
        {
          'swagger' => '2.0',
          'consumes' => ['application/json'],
          'produces' => ['application/json'],
          'paths' => {
            '/swagger_doc.json' => {
              'get' => {
                'summary' => 'The swagger endpoint',
                'tags' => ['swagger'],
                'responses' => {
                  '200' => {}
                }
              },
              'options' => {
                'summary' => 'Option method for the swagger endpoint, useful for some CORS stuff',
                'tags' => ['swagger'],
                'produces' => ['text/plain;charset=utf-8'],
                'responses' => {
                  '200' => {}
                }
              }
            }
          }
        }
      )
    end

    it 'answer when asking for head ' do
      @my_app = MySinatraApp_Minimal
      options('/swagger_doc.json')
      last_response.body.must_equal('')
    end

    it 'should be able to register the module' do
      class MySinatraApp_Register < Sinatra::Base
        register Sinatra::SwaggerExposer
      end
    end

    it 'should fail after a bad description' do
      must_raise_swag_and_equal(
        -> {
          class MySinatraApp_BadDescription < Sinatra::Base
            register Sinatra::SwaggerExposer
            endpoint_description({})
          end
        }, 'description [{}] should be a string')
    end

    it 'should fail after 2 descriptions' do
      must_raise_swag_and_equal(
        -> {
          class MySinatraApp_2Descriptions < Sinatra::Base
            register Sinatra::SwaggerExposer
            endpoint_description 'plap'
            endpoint_description 'plop'
          end
        }, 'description with value [plop] already defined: [plap]')
    end

    it 'should fail after a bad summary' do
      must_raise_swag_and_equal(
        -> {
          class MySinatraApp_BadSummary < Sinatra::Base
            register Sinatra::SwaggerExposer
            endpoint_summary({})
          end
        }, 'summary [{}] should be a string')
    end

    it 'should fail after 2 summaries' do
      must_raise_swag_and_equal(
        -> {
          class MySinatraApp_2Summaries < Sinatra::Base
            register Sinatra::SwaggerExposer
            endpoint_summary 'plap'
            endpoint_summary 'plop'
          end
        }, 'summary with value [plop] already defined: [plap]')
    end

    it 'should fail after a bad path' do
      must_raise_swag_and_equal(
        -> {
          class MySinatraApp_BadPath < Sinatra::Base
            register Sinatra::SwaggerExposer
            endpoint_path({})
          end
        }, 'path [{}] should be a string')
    end

    it 'should fail after 2 pathes' do
      must_raise_swag_and_equal(
        -> {
          class MySinatraApp_2Pathes < Sinatra::Base
            register Sinatra::SwaggerExposer
            endpoint_path 'plap'
            endpoint_path 'plop'
          end
        }, 'path with value [plop] already defined: [plap]')
    end

    it 'should fail after 2 produces' do
      must_raise_swag_and_equal(
        -> {
          class MySinatraApp_2Produces < Sinatra::Base
            register Sinatra::SwaggerExposer
            endpoint_produces 'image/gif'
            endpoint_produces 'application/pdf'
          end
        }, 'produces with value [["application/pdf"]] already defined: [["image/gif"]]')
    end


    it 'should enable to declare info' do
      class MySinatraApp_Info < Sinatra::Base
        register Sinatra::SwaggerExposer
        general_info({:version => '1.0.0'})
      end
      swagger_info = MySinatraApp_Info.swagger_info
      swagger_info.must_be_instance_of Sinatra::SwaggerExposer::Configuration::SwaggerInfo
      swagger_info.to_swagger.must_equal({:version => '1.0.0'})
    end

    it 'should enable to declare a type' do
      class MySinatraApp_DeclareType < Sinatra::Base
        register Sinatra::SwaggerExposer
        type 'status', {}
      end
      swagger_types = MySinatraApp_DeclareType.swagger_types
      swagger_types.types.length.must_equal 1
      swagger_types.types.keys.first.must_equal 'status'
      swagger_type = swagger_types.types.values.first
      swagger_types.key?('status').must_equal true
      swagger_type.must_be_instance_of Sinatra::SwaggerExposer::Configuration::SwaggerType
      swagger_type.to_swagger.must_equal({:type => 'object'})
    end

    it 'should enable to declare a header' do
      class MySinatraApp_DeclareHeader < Sinatra::Base
        register Sinatra::SwaggerExposer
        response_header 'header', String, 'description'
      end
      swagger_response_headers = MySinatraApp_DeclareHeader.swagger_response_headers
      swagger_response_headers.response_headers.length.must_equal 1
      swagger_response_headers.key?('header').must_equal true
      swagger_response_headers.response_headers.keys.first.must_equal 'header'
      header = swagger_response_headers.response_headers.values.first
      header.must_be_instance_of Sinatra::SwaggerExposer::Configuration::SwaggerResponseHeader
      header.to_swagger.must_equal({:type => 'string', :description => 'description'})
    end

    it 'should enable to declare a response code' do
      class MySinatraApp_DeclareResponse < Sinatra::Base
        register Sinatra::SwaggerExposer
        type 'status', {}
        endpoint_response 200, 'status'
      end
      swagger_current_endpoint_responses = MySinatraApp_DeclareResponse.swagger_current_endpoint_responses
      swagger_current_endpoint_responses.length.must_equal 1
      swagger_current_endpoint_responses.keys.first.must_equal 200
      swagger_current_endpoint_responses.values.first.must_be_instance_of Sinatra::SwaggerExposer::Configuration::SwaggerEndpointResponse
    end

    it 'should enable to declare a param' do
      class MySinatraApp_Param < Sinatra::Base
        register Sinatra::SwaggerExposer
        endpoint_parameter 'plop', 'description', :body, true, String
      end
      swagger_current_endpoint_parameters = MySinatraApp_Param.swagger_current_endpoint_parameters
      swagger_current_endpoint_parameters.length.must_equal 1
      swagger_current_endpoint_parameters.keys.first.must_equal 'plop'
      swagger_current_endpoint_parameters.values.first.must_be_instance_of Sinatra::SwaggerExposer::Configuration::SwaggerEndpointParameter
    end

    it 'should fail after 2 types with the same name' do
      must_raise_swag_and_equal(
        -> {
          class MySinatraApp_2TypesWithSameName < Sinatra::Base
            register Sinatra::SwaggerExposer
            type 'status', {}
            type 'status', {}
          end
        }, 'Type [status] already exist with value {"properties":{},"required":[],"example":{}}')
    end

    it 'should fail after 2 responses with the same code' do
      must_raise_swag_and_equal(
        -> {
          class MySinatraApp_2ResponsesSameCode < Sinatra::Base
            register Sinatra::SwaggerExposer
            type 'status', {}
            endpoint_response 200, 'status'
            endpoint_response 200, 'status'
          end
        }, 'Response already exist for 200 with value [{"type":"status","items":null,"description":null}]')
    end

    it 'should fail after 2 params with the same name' do
      must_raise_swag_and_equal(
        -> {
          class MySinatraApp_2ParamsWithSameName < Sinatra::Base
            register Sinatra::SwaggerExposer
            endpoint_parameter 'plop', 'description', :body, true, String
            endpoint_parameter 'plop', 'description', :body, true, String
          end
        }, 'Parameter already exist for plop with value [{"name":"plop","in":"body","required":true,"type":"string","items":null,"description":"description","params":{}}]')
    end

    it 'should register endpoint' do
      class MySinatraApp_RegisterEndpoint < Sinatra::Base
        register Sinatra::SwaggerExposer
        type 'status', {}
        endpoint_response 200, 'status', 'description'
        get '/path' do
          200
        end
      end
      MySinatraApp_RegisterEndpoint.swagger_endpoints.length.must_equal 3
      MySinatraApp_RegisterEndpoint.swagger_endpoints[2].path.must_equal '/path'
      MySinatraApp_RegisterEndpoint.swagger_endpoints[2].type.must_equal 'get'
      MySinatraApp_RegisterEndpoint.swagger_endpoints[2].to_swagger.must_equal(
        {
          :responses => {
            200 => {
              :schema => {'$ref' => '#/definitions/status'},
              :description => 'description'}
          }
        }
      )
    end

    it 'should skip endpoint' do
      class MySinatraApp_SkipEndpoint < Sinatra::Base
        register Sinatra::SwaggerExposer
        get '/path', {:no_swagger => true} do
          200
        end
      end
      MySinatraApp_SkipEndpoint.swagger_endpoints.length.must_equal 2
    end

    it 'should register endpoints with all methods' do
      class MySinatraApp_RegisterEndpointAllMethods < Sinatra::Base
        register Sinatra::SwaggerExposer
        delete '/path' do
          200
        end
        head '/path' do
          200
        end
        get '/path' do
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

      MySinatraApp_RegisterEndpointAllMethods.swagger_endpoints.length.must_equal 10
      @my_app = MySinatraApp_RegisterEndpointAllMethods
      delete 'path'
      get '/path'
      head '/path'
      link '/path'
      options '/path'
      patch '/path'
      post '/path'
      put '/path'
      unlink '/path'
    end

    it 'should call the route with the right params' do
      class MySinatraApp_RouteParams < Sinatra::Base
        register Sinatra::SwaggerExposer

        endpoint_path '/pet/:id'
        endpoint_produces 'text/plain;charset=utf-8'
        endpoint_response 200
        get %r{/pet/(\d+)} do |id|
          content_type :text
          id
        end
      end
      @my_app = MySinatraApp_RouteParams
      get('/pet/999')
      last_response.body.must_equal '999'
    end

    it 'should handle fluent endpoint' do
      class MySinatraApp_RegisterFluentEndpoint < Sinatra::Base
        register Sinatra::SwaggerExposer

        @@cal_counter=0

        # Mock Expectation
        def self.endpoint_summary(sum)
          @@cal_counter+=1
          sum.must_equal 'hello'
        end

        def self.endpoint_path(sum)
          @@cal_counter+=1
          sum.must_equal '/the-path'
        end

        def self.endpoint_description(desc)
          @@cal_counter+=1
          desc.must_equal 'Base method to ping'
        end

        def self.endpoint_response(code, type = nil, description = nil, headers = [])
          @@cal_counter+=1
          code.must_equal 200
          type.must_equal 'Status'
          description.must_equal 'Standard response'
          headers.must_equal ['Header']
        end

        def self.endpoint_parameter(name, description, how_to_pass, required, type, params = {})
          @@cal_counter+=1
          name.must_match /pl.p/
          description.must_equal 'description'
          how_to_pass.must_equal :body
          required.must_equal true
          type.must_be_same_as String
        end

        def self.endpoint_tags(*tags)
          tags.must_equal ['Ping']
          @@cal_counter+=1
        end

        def self.endpoint_produces(*produces)
          produces.must_equal ['image/gif']
          @@cal_counter+=1
        end

        def self.all_called
          @@cal_counter == 8
        end

        type 'status', {}
        endpoint :summary => 'hello',
                 :description => 'Base method to ping',
                 :responses => {200 => ['Status', 'Standard response', ['Header']]},
                 :tags => 'Ping',
                 :path => '/the-path',
                 :produces => 'image/gif',
                 :parameters => {'plop' => ['description', :body, true, String],
                                 'plip' => ['description', :body, true, String]}
        get '/path' do
          200
        end
      end
      MySinatraApp_RegisterFluentEndpoint.all_called.must_equal true
    end

    it 'should fail for unknown parameter in fluent endpoint' do
      must_raise_swag_and_equal(
        -> {
          class MySinatraApp_RegisterFluentEndpointUnknown < Sinatra::Base
            register Sinatra::SwaggerExposer

            type 'status', {}
            endpoint :unknown => 'unknown'
            get '/path' do
              200
            end
          end
        }, 'Invalid endpoint parameter [unknown]')
    end

    class MySinatraApp_Header < Sinatra::Base
      set :logging, true
      register Sinatra::SwaggerExposer

      endpoint_parameter 'X-API-KEY'.to_sym, 'The API key', :header, true, String
      endpoint_response 400
      endpoint_response 200
      get '/status' do
        content_type :json
        halt 200, {:status => 'OK'}.to_json
      end
    end

    it 'should validate params for headers' do
      @my_app = MySinatraApp_Header
      get('/status')
      last_response.status.must_equal 400
      JSON.parse(last_response.body).must_equal({'code' => 400, 'message' => 'Mandatory value [X-API-KEY] is missing'})

      header 'X-API-KEY', 'API-KEY'
      get('/status')
      last_response.status.must_equal 200
      JSON.parse(last_response.body).must_equal({'status' => 'OK'})
    end

  end

end
