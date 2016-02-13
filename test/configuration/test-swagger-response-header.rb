require_relative '../minitest-helper'
require_relative '../test-utilities'

require_relative '../../lib/sinatra/swagger-exposer/configuration/swagger-response-header'

class TestSwaggerResponseHeader < Minitest::Test

  describe Sinatra::SwaggerExposer::Configuration::SwaggerResponseHeader do

    include TestUtilities

    def new_rp(name, type, description)
      Sinatra::SwaggerExposer::Configuration::SwaggerResponseHeader.new(name, type, description)
    end

    it 'must fail with a bad name' do
      must_raise_swag_and_equal(
        -> { new_rp(1, String, 'description') },
        'Name [1] should be a string or a symbol'
      )
      must_raise_swag_and_equal(
        -> { new_rp('', String, 'description') },
        'Name should not be empty'
      )
    end

    it 'must fail with a bad type' do
      must_raise_swag_and_equal(
        -> { new_rp('name', nil, 'description') },
        'Type is nil'
      )
      must_raise_swag_and_equal(
        -> { new_rp('name', 'foo', 'description') },
        'Unknown type [foo], possible types are string, number, integer, boolean'
      )
    end


    it 'must return the right values' do
      new_rp('name', String, nil).to_swagger.must_equal(
        {:type => 'string'}
      )
      new_rp('name', String, 'description').to_swagger.must_equal(
        {:type => 'string', :description => 'description'}
      )
    end

    it 'must answer to to_s' do
      JSON.parse(new_rp('name', String, 'description').to_s).must_equal(
        {'name' => 'name', 'type' => 'string', 'description' => 'description'}
      )
    end

  end

end
