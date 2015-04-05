require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-endpoint-parameter'

class TestSwaggerEndpoint < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerEndpointParameter do

    include TestUtilities

    it 'must fail with a bad name' do
      must_raise_swag_and_match(-> { new_ep(1, 'description', :body, true, String) }, /#{'1'}/)
      must_raise_swag_and_match(-> { new_ep('', 'description', :body, true, String) }, /#{'empty'}/)
    end

    it 'must fail with a bad required' do
      must_raise_swag_and_match(-> { new_ep('name', 'description', :body, 'plop', String) }, /#{'Required'}/)
      must_raise_swag_and_match(-> { new_ep('name', 'description', :body, nil, String) }, /#{'Required'}/)
    end

    it 'must fail with a bad how to pass' do
      must_raise_swag_and_match(-> { new_ep('name', 'description', :plop, true, String) }, /#{'pass'}/)
      must_raise_swag_and_match(-> { new_ep('name', 'description', nil, true, String) }, /#{'pass'}/)
    end

    it 'must fail with a bad type' do
      must_raise_swag_and_match(-> { new_ep('name', 'description', :body, true, nil) }, /#{'nil'}/)
      must_raise_swag_and_match(-> { new_ep('name', 'description', :body, true, 'foo') }, /#{'Unknown'}/)
      must_raise_swag_and_match(-> { new_ep('name', 'description', :body, true, 'query', {}, ['foo']) }, /#{'Unknown'}/)
    end

    it 'must fail with a bad param' do
      must_raise_swag_and_match(-> { new_ep('name', 'description', :query, true, String, {:plop => 'plap'}) }, /#{'plop'}/)
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
    end

    it 'must answer to to_s' do
      JSON.parse(new_ep('name', 'description', :body, true, String).to_s).must_equal(
          {'name' => 'name', 'in' => 'body', 'required' => true, 'type' => 'string', 'items' => nil, 'params' => {}, 'description' => 'description'}
      )
    end

  end

end
