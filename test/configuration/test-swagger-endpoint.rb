require_relative '../minitest-helper'
require_relative '../test-utilities'

require_relative '../../lib/sinatra/swagger-exposer/configuration/swagger-endpoint'

class TestSwaggerEndpoint < Minitest::Test

  describe Sinatra::SwaggerExposer::Configuration::SwaggerEndpoint do

    include TestUtilities

    it 'must make some data accessible' do
      swagger_endpoint = new_e('get', '/')
      swagger_endpoint.type.must_equal 'get'
      swagger_endpoint.path.must_equal '/'
    end

    it 'must fix route' do
      new_e('get', '/pets/:plop').path.must_equal '/pets/{plop}'
      new_e('get', '/pets/:id/:plop').path.must_equal '/pets/{id}/{plop}'
    end

    it 'must fail with a regex path' do
      must_raise_swag_and_equal(
        -> { new_e('get', %r{/pet/(\d+)}, [new_ep('name', 'description', :header, false, String)]) },
        'You need to specify a path when using a non-string path [(?-mix:\\/pet\\/(\\d+))]'
      )
    end

    it 'must use an explicit route' do
      swagger_endpoint = new_e('get', '/pet/:my_pet_id', [new_ep('name', 'description', :header, false, String)], nil, nil, nil, nil, '/pet/:id')
      swagger_endpoint.path.must_equal '/pet/:id'

      swagger_endpoint = new_e('get', %r{/pet/(\d+)}, [new_ep('name', 'description', :header, false, String)], nil, nil, nil, nil, '/pet/:id')
      swagger_endpoint.path.must_equal '/pet/:id'
    end

    it 'must return the right values' do
      new_e('get', '/').to_swagger.must_equal(
        {}
      )
      new_e(
        'get',
        '/',
        [new_ep('foo', 'description', :body, false, String)],
        {200 => new_er('foo', 'description', ['foo'])},
        'summary',
        'description',
        ['tag']
      ).to_swagger.must_equal(
        {
          :summary => 'summary',
          :description => 'description',
          :tags => ['tag'],
          :parameters => [
            {
              :name => 'foo',
              :in => 'body',
              :required => false,
              :type => 'string',
              :description => 'description'
            }
          ],
          :responses => {
            200 => {
              :schema => {'$ref' => '#/definitions/foo'},
              :description => 'description'}
          }
        }
      )
      new_e(
        'get',
        '/',
        [new_ep('foo', 'description', :body, false, String)],
        {200 => new_er('foo', 'description', ['foo'])},
        'summary',
        'description',
        ['tag'],
        nil,
        ['image/gif', 'application/json']
      ).to_swagger.must_equal(
        {
          :summary => 'summary',
          :description => 'description',
          :tags => ['tag'],
          :produces => ['image/gif', 'application/json'],
          :parameters => [
            {
              :name => 'foo',
              :in => 'body',
              :required => false,
              :type => 'string',
              :description => 'description'
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
