require_relative 'minitest-helper'

require_relative '../lib/sinatra/swagger-exposer/swagger-utilities'

class TestSwaggerUtilities < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerUtilities do

    class Swaggable

      def initialize(value)
        @value = value
      end

      def to_swagger
        "#{@value}_swag"
      end

    end

    class SwaggerUtilitiesClass
      include Sinatra::SwaggerExposer::SwaggerUtilities
    end

    it 'should swag an hash' do
      swagger_utilities = SwaggerUtilitiesClass.new
      hash = {
          'key1' => Swaggable.new('value1'),
          'key2' => Swaggable.new('value2')
      }
      swagger_utilities.hash_to_swagger(hash).must_equal(
          {
              'key1' => 'value1_swag',
              'key2' => 'value2_swag'
          })
    end

  end

end
