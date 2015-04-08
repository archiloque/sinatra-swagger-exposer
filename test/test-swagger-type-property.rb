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
      must_raise_swag_and_match(-> { new_tp(nil, nil, :plop) }, /#{'plop'}/)
    end

    it 'must fail with an unknown property' do
      must_raise_swag_and_match(-> { new_tp(nil, nil, {:unknown => 'value'}) }, /#{'unknown'}/)
    end

    it 'must fail with an unknown type' do
      must_raise_swag_and_match(-> { new_tp(nil, nil, {:type => Hash}) }, /#{'hash'}/)
      must_raise_swag_and_match(-> { new_tp(nil, nil, {:type => [Hash]}) }, /#{'hash'}/)
      must_raise_swag_and_match(-> { new_tp(nil, nil, {:type => 'foo'}) }, /#{'foo'}/)
      must_raise_swag_and_match(-> { new_tp(nil, nil, {:type => 'foo'}) }, /#{'foo'}/)
    end

    it 'must fail with a bad type' do
      must_raise_swag_and_match(-> { new_tp(nil, nil, {:type => 12}) }, /#{'unknown'}/)
    end

    it 'must fail with a bad array type' do
      must_raise_swag_and_match(-> { new_tp(nil, nil, {:type => []}) }, /#{'empty array'}/)
      must_raise_swag_and_match(-> { new_tp(nil, nil, {:type => ['', '']}) }, /#{'more than one'}/)
    end

    it 'must return the right values' do
      new_tp(nil, nil, {:type => 'boolean'}).to_swagger.must_equal({:type => 'boolean'})
      new_tp(nil, nil, {:type => TrueClass}).to_swagger.must_equal({:type => 'boolean'})
      new_tp(nil, nil, {:type => FalseClass}).to_swagger.must_equal({:type => 'boolean'})

      new_tp(nil, nil, {:type => String}).to_swagger.must_equal({:type => 'string'})
      new_tp(nil, nil, {:type => 'string', }).to_swagger.must_equal({:type => 'string'})

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
