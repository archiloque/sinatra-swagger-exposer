require_relative '../minitest-helper'
require_relative '../test-utilities'

require_relative '../../lib/sinatra/swagger-exposer/configuration/swagger-type'

class TestSwaggerType < Minitest::Test

  describe Sinatra::SwaggerExposer::Configuration::SwaggerType do

    include TestUtilities

    it 'must fail with a bad properties type' do
      must_raise_swag_and_equal(
        -> { new_t(nil, {:properties => []}) },
        'Attribute [properties] of  is not an hash: []'
      )
    end

    it 'must fail with an unknown properties type' do
      must_raise_swag_and_equal(
        -> { new_t(nil, {:plop => []}) },
        'Unknown property [plop] with value [[]], possible properties are properties, required, example, extends'
      )
    end

    it 'must fail with a bad required type' do
      must_raise_swag_and_equal(
        -> { new_t(nil, {:required => {}}) },
        'Attribute [required] of  is not an hash: {}'
      )
    end

    it 'must fail with an unknown required' do
      must_raise_swag_and_equal(
        -> { new_t(nil, {:required => ['foo']}) },
        'Required property [foo] of [] is unknown, no available properties'
      )
    end

    it 'must fail with a bad example type' do
      must_raise_swag_and_equal(
        -> { new_t('plop', {:example => []}) },
        'Attribute [example] of plop is not an hash: []'
      )
    end

    it 'must fail with an unknown example' do
      must_raise_swag_and_equal(
        -> { new_t(nil, {:example => {:foo => 'bar'}}) },
        'Example property [foo] with value [bar] of [] is unknown, no available properties'
      )
    end

    it 'must fail when extends an unknown type' do
      must_raise_swag_and_equal(
        -> { new_t(nil, {:extends => 'foo'}) },
        'Unknown type [foo], no available type'
      )
    end

    it 'must return the right values' do
      new_t(nil, {}).to_swagger.must_equal({:type => 'object'})
      new_t(nil, {:properties => {}}).to_swagger.must_equal({:type => 'object'})

      new_t(nil, {:properties => {:foo => {:type => String}}}).to_swagger.must_equal(
        {:type => 'object', :properties => {'foo' => {:type => 'string'}}}
      )

      new_t(nil, {:properties => {:foo => {:type => String}}, :extends => 'bar'}, ['bar']).to_swagger.must_equal(
        {:allOf => [{'$ref' => '#/definitions/bar'}, {:type => 'object', :properties => {'foo' => {:type => 'string'}}}]}
      )

      new_t(nil, {:properties => {:foo => {:type => String}}, :required => [:foo], :example => {:foo => 'bar'}}).to_swagger.must_equal(
        {:type => 'object', :properties => {'foo' => {:type => 'string'}}, :required => [:foo], :example => {:foo => 'bar'}}
      )
    end


  end

end
