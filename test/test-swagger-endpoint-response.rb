require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-endpoint-response'

class TestSwaggerEndpointResponse < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerEndpointResponse do

    include TestUtilities

    def new_er(description, type, known_types)
      Sinatra::SwaggerExposer::SwaggerEndpointResponse.new(description, type, known_types)
    end

    it 'must fail with a bad type' do
      must_raise_swag_and_match(-> { new_er(nil, 1, []) }, /#{'1'}/)
      must_raise_swag_and_match(-> { new_er(nil, [1], []) }, /#{1}/)
    end

    it 'must fail with a unknown type' do
      must_raise_swag_and_match(-> { new_er(nil, 'foo', []) }, /#{'foo'}/)
      must_raise_swag_and_match(-> { new_er(nil, ['foo'], []) }, /#{'foo'}/)
    end

    it 'must return the right values' do
      new_er(nil, 'foo', ['foo']).to_swagger.must_equal(
          {:schema => {'$ref' => '#/definitions/foo'}}
      )
      new_er('description', 'foo', ['foo']).to_swagger.must_equal(
          {:schema => {'$ref' => '#/definitions/foo'}, :description => 'description'}
      )
      new_er(nil, ['foo'], ['foo']).to_swagger.must_equal(
          {:schema => {:type => 'array', :items => {'$ref' => '#/definitions/foo'}}}
      )
    end


  end

end
