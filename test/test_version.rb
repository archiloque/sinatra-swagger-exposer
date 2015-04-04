require_relative 'minitest_helper'
require_relative '../lib/sinatra/swagger-exposer/version'

class TestVersion < Minitest::Test

  describe 'when asked for a version number' do
    it 'must respond with one' do
      ::Sinatra::SwaggerExposer::VERSION.wont_be_nil
    end
  end

end
