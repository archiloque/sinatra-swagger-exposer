require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-type'

class TestSwaggerType < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerType do

    include TestUtilities

    def new_t(type_name, type_content)
      Sinatra::SwaggerExposer::SwaggerType.new(type_name, type_content)
    end

    it 'must fail with a bad properties type' do
      must_raise_swag_and_match(-> { new_t(nil, {:properties => []}) }, /#{'properties'}/)
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

    it 'must return the right values' do
      new_t(nil, {}).to_swagger.must_equal({})
      new_t(nil, {:properties => {}}).to_swagger.must_equal({})

      new_t(nil, {:properties => {:foo => {:type => String}}}).to_swagger.must_equal(
          {:properties => {'foo' => {:type => 'string'}}}
      )

      new_t(nil, {:properties => {:foo => {:type => String}}, :required => [:foo], :example => {:foo => 'bar'}}).to_swagger.must_equal(
          {:properties => {'foo' => {:type => 'string'}}, :required => [:foo], :example => {:foo => 'bar'}}
      )
    end


  end

end
