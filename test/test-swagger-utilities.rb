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
      must_raise_swag_and_equal(
      -> { swagger_utilities.white_list_params({:plop => 'plap'}, [:plip]) },
      'Unknown property [plop] with value [plap], possible properties are plip'
      )
      must_raise_swag_and_equal(
      -> { swagger_utilities.white_list_params({:plop => 'plap', :plip => 'plup'}, [:plip]) },
      'Unknown property [plop] with value [plap], possible properties are plip'
      )
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

      must_raise_swag_and_equal(
      -> { SwaggerUtilitiesClass.new().get_type(['foo'], []) },
      'Unknown type [foo], no available type'
      )
      must_raise_swag_and_equal(
      -> { SwaggerUtilitiesClass.new().get_type(Hash.new, []) },
      'Type [{}] of has an unknown type, should be a class, a string or an array'
      )
      must_raise_swag_and_equal(
      -> { SwaggerUtilitiesClass.new().get_type(nil, []) },
      'Type is nil'
      )
      must_raise_swag_and_equal(
      -> { SwaggerUtilitiesClass.new().get_type([], []) },
      'Type is an empty array, you should specify a type as the array content'
      )
      must_raise_swag_and_equal(
      -> { SwaggerUtilitiesClass.new().get_type([1, 2], []) },
      'Type [[1, 2]] has more than one entry, it should only have one'
      )
    end

  end

end
