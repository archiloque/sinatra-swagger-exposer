require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-type'

class TestSwaggerType < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerType do

    include TestUtilities

    it 'must fail with a bad properties type' do
      must_raise_swag_and_match(-> { new_t(nil, {:properties => []}) }, /#{'properties'}/)
    end

    it 'must fail with an unknown properties type' do
      must_raise_swag_and_match(-> { new_t(nil, {:plop => []}) }, /#{'plop'}/)
    end

    it 'must fail with a bad required type' do
      must_raise_swag_and_match(-> { new_t(nil, {:required => {}}) }, /#{'required'}/)
    end

    it 'must fail with an unknown required' do
      must_raise_swag_and_match(-> { new_t(nil, {:required => ['foo']}) }, /#{'foo'}/)
    end

    it 'must fail with a bad example type' do
      must_raise_swag_and_match(-> { new_t(nil, {:example => []}) }, /#{'example'}/)
    end

    it 'must fail with an unknown example' do
      must_raise_swag_and_match(-> { new_t(nil, {:example => {:foo => 'bar'}}) }, /#{'foo'}/)
    end

    it 'must fail when extends an unknown type' do
      must_raise_swag_and_match(-> { new_t(nil, {:extends => 'foo'}) }, /#{'foo'}/)
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
