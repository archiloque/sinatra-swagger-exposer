require_relative '../minitest-helper'
require_relative '../test-utilities'

require_relative '../../lib/sinatra/swagger-exposer/configuration/swagger-endpoint-parameter'

class TestSwaggerEndpointParameter < Minitest::Test

  describe Sinatra::SwaggerExposer::Configuration::SwaggerEndpointParameter do

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
        'Unknown how to pass value [plop], possible registered types are body, formData, header, path, query'
      )
      must_raise_swag_and_equal(
        -> { new_ep('name', 'description', nil, true, String) },
        'Unknown how to pass value [], possible registered types are body, formData, header, path, query'
      )
    end

    it 'must fail with a bad type' do
      must_raise_swag_and_equal(
        -> { new_ep('name', 'description', :body, true, nil) },
        'Type is nil'
      )
      must_raise_swag_and_equal(
        -> { new_ep('name', 'description', :body, true, 'foo') },
        'Unknown type [foo], possible types are boolean, byte, date, dateTime, double, file, float, integer, long, password, string'
      )
      must_raise_swag_and_equal(
        -> { new_ep('name', 'description', :body, true, 'query', {}, ['foo']) },
        'Unknown type [query], possible types are boolean, byte, date, dateTime, double, file, float, foo, integer, long, password, string'
      )
    end

    it 'must fail with a bad param' do
      must_raise_swag_and_equal(
        -> { new_ep('name', 'description', :query, true, String, {:plop => 'plap'}) },
        'Unknown property [plop] with value [plap], possible properties are default, example, exclusiveMaximum, exclusiveMinimum, format, maxLength, maximum, minLength, minimum'
      )
    end

    it 'must accept unused type parameters' do
      new_ep('name', 'description', :query, true, String, {:type => String}).to_swagger.must_equal(
        {:name => 'name', :in => 'query', :required => true, :type => 'string', :description => 'description'}
      )
    end

    def validate_bad_limit(name, exclusive_name)
      must_raise_swag_and_equal(
        -> { new_ep('name', 'description', :query, true, String, {name => 'plap'}) },
        "Parameter #{name} can only be specified for types integer or number and not for [string]"
      )
      must_raise_swag_and_equal(
        -> { new_ep('name', 'description', :query, true, TrueClass, {name => 'plap'}) },
        "Parameter #{name} can only be specified for types integer or number and not for [boolean]"
      )
      must_raise_swag_and_equal(
        -> { new_ep('name', 'description', :query, true, Integer, {name => 'plop'}) },
        "Parameter #{name} must be a numeric and can not be [plop]"
      )

      must_raise_swag_and_equal(
        -> { new_ep('name', 'description', :query, true, Integer, {name => 10, exclusive_name => 'plap'}) },
        "Invalid boolean value [plap] for [#{exclusive_name}]"
      )
      must_raise_swag_and_equal(
        -> { new_ep('name', 'description', :query, true, Integer, {exclusive_name => false}) },
        "You can't have a #{exclusive_name} value without a #{name}"
      )
    end

    it 'must fail with a bad maximum' do
      validate_bad_limit(:maximum, :exclusiveMaximum)
    end

    it 'must fail with a bad minimum' do
      validate_bad_limit(:minimum, :exclusiveMinimum)
    end

    it 'must fail when minimum is more than maximum' do
      must_raise_swag_and_equal(
        -> { new_ep('name', 'description', :query, true, Integer, {:minimum => 10, :maximum => 8}) },
        'Minimum value [10] can\'t be more than maximum value [8]'
      )
    end

    def validate_bad_limit_length(name)
      must_raise_swag_and_equal(
        -> { new_ep('name', 'description', :query, true, Integer, {name => 'plap'}) },
        "Parameter #{name} can only be specified for type string and not for [integer]"
      )

      must_raise_swag_and_equal(
        -> { new_ep('name', 'description', :query, true, String, {name => 'plop'}) },
        "Parameter #{name} must be an integer and can not be [plop]"
      )
    end

    it 'must fail with a bad max length' do
      validate_bad_limit_length(:maxLength)
    end
    it 'must fail with a bad min length' do
      validate_bad_limit_length(:minLength)
    end

    it 'must fail when min length is more than max length' do
      must_raise_swag_and_equal(
        -> { new_ep('name', 'description', :query, true, String, {:minLength => 10, :maxLength => 8}) },
        'Minimum length 10 can\'t be more than maximum length 8'
      )
    end

    def validate_right_length_limit_value(name)
      new_ep('name', 'description', :query, true, String, {name => 10}).to_swagger.must_equal(
        {:name => 'name', :in => 'query', :required => true, :type => 'string', :description => 'description', name => 10}
      )
    end

    def validate_right_limit_value(name, exclusive_name)
      new_ep('name', 'description', :query, true, Integer, {name => 10}).to_swagger.must_equal(
        {:name => 'name', :in => 'query', :required => true, :type => 'integer', :description => 'description', name => 10}
      )
      new_ep('name', 'description', :query, true, Integer, {name => 10, exclusive_name => false}).to_swagger.must_equal(
        {:name => 'name', :in => 'query', :required => true, :type => 'integer', :description => 'description', name => 10, exclusive_name => false}
      )
      new_ep('name', 'description', :query, true, Integer, {name => 10, exclusive_name => true}).to_swagger.must_equal(
        {:name => 'name', :in => 'query', :required => true, :type => 'integer', :description => 'description', name => 10, exclusive_name => true}
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

      validate_right_limit_value(:maximum, :exclusiveMaximum)
      validate_right_limit_value(:minimum, :exclusiveMinimum)

      validate_right_length_limit_value(:minLength)
      validate_right_length_limit_value(:maxLength)

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
