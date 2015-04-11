require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-endpoint-parameter'

class TestSwaggerEndpoint < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerEndpointParameter do

    include TestUtilities

    it 'must fail with a bad name' do
      must_raise_swag_and_equal(
      -> { new_ep(1, 'description', :body, true, String) },
      'Name [1] should be a string or a symbol'
      )
      must_raise_swag_and_equal(
      -> { new_ep('', 'description', :body, true, String) },
      'Name should not be empty'
      )
    end

    it 'must fail with a bad required' do
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', :body, 'plop', String) },
      'Required should be a boolean instead of [plop]'
      )
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', :body, nil, String) },
      'Required should be a boolean instead of []'
      )
    end

    it 'must fail with a bad how to pass' do
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', :plop, true, String) },
      'Unknown how to pass value [plop], possible registered types are path, query, header, formData, body'
      )
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', nil, true, String) },
      'Unknown how to pass value [], possible registered types are path, query, header, formData, body'
      )
    end

    it 'must fail with a bad type' do
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', :body, true, nil) },
      'Type is nil'
      )
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', :body, true, 'foo') },
      'Unknown type [foo], possible types are integer, long, float, double, string, byte, boolean, date, dateTime, password'
      )
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', :body, true, 'query', {}, ['foo']) },
      'Unknown type [query], possible types are integer, long, float, double, string, byte, boolean, date, dateTime, password, foo'
      )
    end

    it 'must fail with a bad param' do
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', :query, true, String, {:plop => 'plap'}) },
      'Unknown property [plop] with value [plap], possible properties are format, default, example, maximum, minimum, exclusiveMinimum, exclusiveMaximum'
      )
    end

    it 'must fail with a bad maximum' do
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', :query, true, String, {:maximum => 'plap'}) },
      'Parameter maximum can only be specified for type integer and number and not for [string]'
      )
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', :query, true, TrueClass, {:maximum => 'plap'}) },
      'Parameter maximum can only be specified for type integer and number and not for [boolean]'
      )
    end

    it 'must fail with a bad exclusiveMaximum' do
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', :query, true, Integer, {:maximum => 10, :exclusiveMaximum => 'plap'}) },
      'Invalid boolean value [plap] for [exclusiveMinimum]'
      )
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', :query, true, Integer, {:exclusiveMaximum => false}) },
      'You can\'t have a exclusiveMaximum value without a maximum'
      )
    end

    it 'must fail with a bad minimum' do
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', :query, true, String, {:minimum => 'plap'}) },
      'Parameter minimum can only be specified for type integer and number and not for [string]'
      )
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', :query, true, TrueClass, {:minimum => 'plap'}) },
      'Parameter minimum can only be specified for type integer and number and not for [boolean]'
      )
    end

    it 'must fail with a bad exclusiveMinimum' do
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', :query, true, Integer, {:minimum => 10, :exclusiveMinimum => 'plap'}) },
      'Invalid boolean value [plap] for [exclusiveMinimum]'
      )
      must_raise_swag_and_equal(
      -> { new_ep('name', 'description', :query, true, Integer, {:exclusiveMinimum => false}) },
      'You can\'t have a exclusiveMinimum value without a minimum'
      )
    end

    it 'must return the right values' do
      new_ep('name', 'description', :query, true, String).to_swagger.must_equal(
          {:name => 'name', :in => 'query', :required => true, :type => 'string', :description => 'description'}
      )
      new_ep('name', 'description', :query, false, String).to_swagger.must_equal(
          {:name => 'name', :in => 'query', :required => false, :type => 'string', :description => 'description'}
      )
      new_ep('name', 'description', :body, true, String).to_swagger.must_equal(
          {:name => 'name', :in => 'body', :required => true, :type => 'string', :description => 'description'}
      )
      new_ep('name', 'description', :body, true, [String]).to_swagger.must_equal(
          {:name => 'name', :in => 'body', :required => true, :type => 'array', :items => {:type => 'string'}, :description => 'description'}
      )
      new_ep('name', 'description', :body, true, [String], {:format => 'csv'}).to_swagger.must_equal(
          {:name => 'name', :in => 'body', :required => true, :type => 'array', :items => {:type => 'string'}, :description => 'description', :format => 'csv'}
      )
      new_ep('name', 'description', :body, true, 'foo', {}, ['foo']).to_swagger.must_equal(
          {:name => 'name', :in => 'body', :required => true, :schema => {'$ref' => '#/definitions/foo'}, :description => 'description'}
      )
      new_ep('name', 'description', :body, true, ['foo'], {}, ['foo']).to_swagger.must_equal(
          {:name => 'name', :in => 'body', :required => true, :type => 'array', :schema => {'$ref' => '#/definitions/foo'}, :description => 'description'}
      )

      new_ep('name', 'description', :query, true, Integer).to_swagger.must_equal(
          {:name => 'name', :in => 'query', :required => true, :type => 'integer', :description => 'description'}
      )

      new_ep('name', 'description', :query, true, Integer, {:maximum => 10}).to_swagger.must_equal(
          {:name => 'name', :in => 'query', :required => true, :type => 'integer', :description => 'description', :maximum => 10}
      )
      new_ep('name', 'description', :query, true, Integer, {:maximum => 10, :exclusiveMaximum => false}).to_swagger.must_equal(
          {:name => 'name', :in => 'query', :required => true, :type => 'integer', :description => 'description', :maximum => 10, :exclusiveMaximum => false}
      )
      new_ep('name', 'description', :query, true, Integer, {:maximum => 10, :exclusiveMaximum => true}).to_swagger.must_equal(
          {:name => 'name', :in => 'query', :required => true, :type => 'integer', :description => 'description', :maximum => 10, :exclusiveMaximum => true}
      )

      new_ep('name', 'description', :query, true, Integer, {:maximum => 10}).to_swagger.must_equal(
          {:name => 'name', :in => 'query', :required => true, :type => 'integer', :description => 'description', :maximum => 10}
      )
      new_ep('name', 'description', :query, true, Integer, {:minimum => 10, :exclusiveMinimum => false}).to_swagger.must_equal(
          {:name => 'name', :in => 'query', :required => true, :type => 'integer', :description => 'description', :minimum => 10, :exclusiveMinimum => false}
      )
      new_ep('name', 'description', :query, true, Integer, {:minimum => 10, :exclusiveMinimum => true}).to_swagger.must_equal(
          {:name => 'name', :in => 'query', :required => true, :type => 'integer', :description => 'description', :minimum => 10, :exclusiveMinimum => true}
      )

      new_ep('name', 'description', :query, true, Integer, {:maximum => 10, :minimum => 1}).to_swagger.must_equal(
          {:name => 'name', :in => 'query', :required => true, :type => 'integer', :description => 'description', :maximum => 10, :minimum => 1}
      )
      new_ep('name', 'description', :query, true, Integer,
             {:minimum => 10, :exclusiveMinimum => true, :maximum => 10, :exclusiveMaximum => true}
      ).to_swagger.must_equal(
          {
              :name => 'name',
              :in => 'query',
              :required => true,
              :type => 'integer',
              :description => 'description',
              :minimum => 10,
              :exclusiveMinimum => true,
              :maximum => 10,
              :exclusiveMaximum => true
          }
      )
    end

    it 'must answer to to_s' do
      JSON.parse(new_ep('name', 'description', :body, true, String).to_s).must_equal(
          {'name' => 'name', 'in' => 'body', 'required' => true, 'type' => 'string', 'items' => nil, 'params' => {}, 'description' => 'description'}
      )
    end

  end

end
