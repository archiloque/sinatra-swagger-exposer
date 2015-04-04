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

    it 'must return the right values' do
      new_e('get', '/').to_swagger.must_equal(
          {:produces => ['application/json']}
      )
      new_e('get', '/', {200 => new_er()}, 'summary', 'description', ['tag']).to_swagger.must_equal(
          {:produces => ['application/json'], :summary => 'summary', :description => 'description', :tags => ['tag'], :responses => {200 => {}}}
      )
    end


  end

end
