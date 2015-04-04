require_relative 'minitest-helper'

require_relative '../lib/sinatra/swagger-exposer/swagger-endpoint'
require_relative '../lib/sinatra/swagger-exposer/swagger-endpoint-response'

class TestSwaggerEndpoint < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerEndpoint do

    def new_e(type, path, responses, summary, description, tags)
      Sinatra::SwaggerExposer::SwaggerEndpoint.new(type, path, responses, summary, description, tags)
    end

    it 'must make some data accessible' do
      swagger_endpoint = new_e('get', '/', [], nil, nil, nil)
      swagger_endpoint.type.must_equal 'get'
      swagger_endpoint.path.must_equal '/'
    end

    it 'must return the right values' do
      new_e('get', '/', [], nil, nil, nil).to_swagger.must_equal(
          {:produces => ['application/json']}
      )
      new_e('get', '/', {200 => Sinatra::SwaggerExposer::SwaggerEndpointResponse.new(nil, nil, [])}, 'summary', 'description', ['tag']).to_swagger.must_equal(
          {:produces => ['application/json'], :summary => 'summary', :description => 'description', :tags => ['tag'], :responses => {200 => {}}}
      )
    end


  end

end
