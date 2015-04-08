require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-endpoint'

class TestSwaggerEndpoint < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerEndpoint do

    include TestUtilities

    it 'must make some data accessible' do
      swagger_endpoint = new_e('get', '/')
      swagger_endpoint.type.must_equal 'get'
      swagger_endpoint.path.must_equal '/'
    end

    it 'must create the request preprocessors and fill them' do
      swagger_endpoint = new_e('get', '/')
      swagger_endpoint.request_preprocessor.preprocessors.length.must_equal 0

      swagger_endpoint = new_e('get', '/', [new_ep('name', 'description', :header, true, String)])
      swagger_endpoint.request_preprocessor.preprocessors.length.must_equal 1

      swagger_endpoint = new_e('get', '/', [new_ep('name', 'description', :header, false, String)])
      swagger_endpoint.request_preprocessor.preprocessors.length.must_equal 0
    end

    it 'must fix route' do
      new_e('get', '/pets/:plop').path.must_equal '/pets/{plop}'
      new_e('get', '/pets/:id/:plop').path.must_equal '/pets/{id}/{plop}'
    end

    it 'must return the right values' do
      new_e('get', '/').to_swagger.must_equal(
          {:produces => ['application/json']}
      )
      new_e(
          'get',
          '/',
          [new_ep('foo', 'description', :body, false, String)],
          {200 => new_er('foo', 'description', ['foo'])},
          'summary',
          'description',
          ['tag']).to_swagger.must_equal(
          {
              :produces => ['application/json'],
              :summary => 'summary',
              :description => 'description',
              :tags => ['tag'],
              :parameters => [
                  {
                      :name => "foo",
                      :in => "body",
                      :required => false,
                      :type => "string",
                      :description => "description"
                  }
              ],
              :responses => {
                  200 => {
                      :schema => {'$ref' => '#/definitions/foo'},
                      :description => 'description'}
              }
          }
      )
    end

    it 'must answer to to_s' do
      JSON.parse(new_e('get', '/').to_s).must_equal(
          {'type' => 'get', 'path' => '/', 'attributes' => {}, 'parameters' => [], 'responses' => {}}
      )
    end

  end

end
