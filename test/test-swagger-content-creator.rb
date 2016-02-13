require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-content-creator'

class TestSwaggerContentCreator < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerContentCreator do

    include TestUtilities

    def new_cc(swagger_info = nil, swagger_types_hash = {}, swagger_endpoints = [])
      swagger_types = Sinatra::SwaggerExposer::Configuration::SwaggerTypes.new
      swagger_types_hash.each_pair do |name, type|
        swagger_types.add_type(name, type)
      end
      Sinatra::SwaggerExposer::SwaggerContentCreator.new(swagger_info, swagger_types, swagger_endpoints)
    end

    it 'must return the right values' do
      new_cc().to_swagger.must_equal(
        {:swagger => '2.0', :consumes => ['application/json'], :produces => ['application/json']}
      )

      new_cc(new_info({:version => '1.0.0'})).to_swagger.must_equal(
        {:swagger => '2.0', :consumes => ['application/json'], :produces => ['application/json'], :info => {:version => '1.0.0'}}
      )

      new_cc(nil, {'plop' => {}}).to_swagger.must_equal(
        {:swagger => '2.0', :consumes => ['application/json'], :produces => ['application/json'], :definitions => {'plop' => {:type => 'object'}}}
      )

      new_cc(
        nil,
        {},
        [
          new_e('get', '/'),
          new_e('post', '/'),
          new_e('get', '/foo')
        ]
      ).to_swagger.must_equal(
        {
          :swagger => '2.0',
          :consumes => ['application/json'],
          :produces => ['application/json'],
          :paths => {
            '/' => {
              'get' => {},
              'post' => {}
            },
            '/foo' => {
              'get' => {}
            }
          }
        }
      )
    end

  end

end
