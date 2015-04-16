require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-type-property'

class TestSwaggerTypeProperty < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerTypeProperty do

    include TestUtilities

    def new_tp(type_name, property_name, property_properties, known_types = [])
      Sinatra::SwaggerExposer::SwaggerTypeProperty.new(type_name, property_name, property_properties, known_types)
    end

    it 'must fail with a bad property type' do
      must_raise_swag_and_equal(
      -> { new_tp(nil, nil, :plop) },
      'Property [] value [plop] of [] should be a hash'
      )
    end

    it 'must fail with an unknown property' do
      must_raise_swag_and_equal(
      -> { new_tp(nil, nil, {:unknown => 'value'}) },
      'Unknown property [unknown] with value [value], possible properties are type, example, description, format, minLength, maxLength'
      )
    end

    it 'must fail with an unknown type' do
      must_raise_swag_and_equal(
      -> { new_tp(nil, nil, {:type => Hash}) },
      'Unknown type [hash], possible types are integer, long, float, double, string, byte, boolean, date, dateTime, password'
      )
      must_raise_swag_and_equal(
      -> { new_tp(nil, nil, {:type => [Hash]}) },
      'Unknown type [hash], possible types are integer, long, float, double, string, byte, boolean, date, dateTime, password'
      )
      must_raise_swag_and_equal(
      -> { new_tp(nil, nil, {:type => 'foo'}) },
      'Unknown type [foo], possible types are integer, long, float, double, string, byte, boolean, date, dateTime, password'
      )
    end

    it 'must fail with a bad type' do
      must_raise_swag_and_equal(
      -> { new_tp(nil, nil, {:type => 12}) },
      'Type [12] of has an unknown type, should be a class, a string or an array'
      )
    end

    it 'must fail with a bad array type' do
      must_raise_swag_and_equal(
      -> { new_tp(nil, nil, {:type => []}) },
      'Type is an empty array, you should specify a type as the array content'
      )
      must_raise_swag_and_equal(
      -> { new_tp(nil, nil, {:type => ['', '']}) },
      'Type [["", ""]] has more than one entry, it should only have one'
      )
    end

    it 'must return the right values' do
      new_tp(nil, nil, {:type => 'boolean'}).to_swagger.must_equal({:type => 'boolean'})
      new_tp(nil, nil, {:type => TrueClass}).to_swagger.must_equal({:type => 'boolean'})
      new_tp(nil, nil, {:type => FalseClass}).to_swagger.must_equal({:type => 'boolean'})

      new_tp(nil, nil, {:type => String}).to_swagger.must_equal({:type => 'string'})
      new_tp(nil, nil, {:type => 'string', }).to_swagger.must_equal({:type => 'string'})

      new_tp(nil, nil, {:type => String, :minLength => 10}).to_swagger.must_equal({:type => 'string', :minLength => 10})
      new_tp(nil, nil, {:type => String, :maxLength => 10}).to_swagger.must_equal({:type => 'string', :maxLength => 10})

      new_tp(nil, nil, {:description => 'Foo'}).to_swagger.must_equal({:description => 'Foo'})
      new_tp(nil, nil, {:example => 'Foo', }).to_swagger.must_equal({:example => 'Foo'})

      new_tp(nil, nil, {:type => ['string'], }).to_swagger.must_equal({:type => 'array', :items => {:type => 'string'}})
      new_tp(nil, nil, {:type => [String], }).to_swagger.must_equal({:type => 'array', :items => {:type => 'string'}})

      new_tp(nil, nil, {:type => 'foo', }, ['foo']).to_swagger.must_equal({'$ref' => '#/definitions/foo'})
      new_tp(nil, nil, {:type => ['foo']}, ['foo']).to_swagger.must_equal({:type => 'array', :items => {'$ref' => '#/definitions/foo'}})
    end

    it 'must answer to to_s' do
      JSON.parse(new_tp(nil, nil, {:type => String}).to_s).must_equal({'name' => nil, 'type' => 'string', 'items' => nil, 'other_properties' => {}})
    end

  end

end
