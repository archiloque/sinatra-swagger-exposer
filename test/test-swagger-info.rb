require_relative 'minitest-helper'
require_relative 'test-utilities'

require_relative '../lib/sinatra/swagger-exposer/swagger-info'

class TestSwaggerInfo < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerInfo do

    include TestUtilities

    def new_info(content)
      Sinatra::SwaggerExposer::SwaggerInfo.new(content)
    end

    it 'must fail with a unknown values' do
      must_raise_swag_and_match(-> { new_info({:unknwown => :something})}, /#{'unknown'}/)
      must_raise_swag_and_match(-> { new_info({:contact => {:unknwown => :something}})}, /#{'unknown'}/)
    end

    it 'must fail when a top level hash value has a wrong type' do
      must_raise_swag_and_match(-> { new_info({:contact => []})}, /#{'contact'}/)
      must_raise_swag_and_match(-> { new_info({:contact => 'plop'})}, /#{'contact'}/)
    end

    it 'must fail when a top level string value has a wrong type' do
      must_raise_swag_and_match(-> { new_info({:title => []})}, /#{'title'}/)
      must_raise_swag_and_match(-> { new_info({:title => {}})}, /#{'title'}/)
    end

    it 'must fail when a second level string value has a wrong type' do
      must_raise_swag_and_match(-> { new_info({:contact => {:name => []}})}, /#{'name'}/)
      must_raise_swag_and_match(-> { new_info({:contact => {:name => {}}})}, /#{'name'}/)
    end

    it 'must return the right values' do
      content = {:contact => {:name => 'me'}, :version => '1.0'}
      new_info(content).to_swagger.must_equal content
    end

    it 'must return the values with keys as symbols' do
      content_string = {'contact' => {'name' => 'me'}, 'version' => '1.0'}
      content_symbol = {:contact => {:name => 'me'}, :version => '1.0'}
      new_info(content_string).to_swagger.must_equal content_symbol
    end

    it 'must return nil when there is no property' do
      new_info({}).to_swagger.must_be_nil
    end


  end

end
