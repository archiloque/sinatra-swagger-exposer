require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-utilities'

class TestSwaggerUtilities < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerUtilities do

    include TestUtilities

    class Swaggable

      def initialize(value)
        @value = value
      end

      def to_swagger
        "#{@value}_swag"
      end

    end

    class SwaggerUtilitiesClass
      attr_reader :type, :items
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

    it 'should transform a string or a class to a string' do
      swagger_utilities = SwaggerUtilitiesClass.new
      swagger_utilities.type_to_s(String).must_equal 'string'
      swagger_utilities.type_to_s('string').must_equal 'string'
    end

    it 'must whitelist parameters' do
      swagger_utilities = SwaggerUtilitiesClass.new
      swagger_utilities.white_list_params({:plop => 'plap'}, [:plop])
      must_raise_swag_and_match(-> { swagger_utilities.white_list_params({:plop => 'plap'}, [:plip]) }, /#{'plop'}/)
      must_raise_swag_and_match(-> { swagger_utilities.white_list_params({:plop => 'plap', :plip => 'plup'}, [:plip]) }, /#{'plop'}/)
    end

    it 'must check types parameters' do
      swagger_utilities = SwaggerUtilitiesClass.new
      swagger_utilities.get_type('string', ['string'])
      swagger_utilities.type.must_equal 'string'
      swagger_utilities.items.must_be_nil

      swagger_utilities = SwaggerUtilitiesClass.new
      swagger_utilities.get_type(['string'], ['string'])
      swagger_utilities.type.must_equal 'array'
      swagger_utilities.items.must_equal 'string'

      must_raise_swag_and_match(-> { SwaggerUtilitiesClass.new().get_type(['foo'],[]) }, /#{'foo'}/)
      must_raise_swag_and_match(-> { SwaggerUtilitiesClass.new().get_type(Hash.new,[]) }, /#{'unknown'}/)
      must_raise_swag_and_match(-> { SwaggerUtilitiesClass.new().get_type(nil,[]) }, /#{'nil'}/)
      must_raise_swag_and_match(-> { SwaggerUtilitiesClass.new().get_type([],[]) }, /#{'empty'}/)
      must_raise_swag_and_match(-> { SwaggerUtilitiesClass.new().get_type([1, 2],[]) }, /#{'one'}/)
    end

  end

end
