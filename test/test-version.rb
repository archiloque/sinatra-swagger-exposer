require_relative 'minitest-helper'
require_relative '../lib/sinatra/swagger-exposer/version'

class TestSwaggerInfo < Minitest::Test

  describe Sinatra::SwaggerExposer::VERSION do
    it 'must define a version' do
      ::Sinatra::SwaggerExposer::VERSION.wont_be_nil
    end
  end

end
