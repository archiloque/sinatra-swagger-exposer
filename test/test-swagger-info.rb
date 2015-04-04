require_relative 'minitest-helper'
require_relative '../lib/sinatra/swagger-exposer/swagger-info'

class TestVersion < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerInfo do

    def new_info(content)
      Sinatra::SwaggerExposer::SwaggerInfo.new(content)
    end

    def must_raise_swag(expression)
      expression.must_raise Sinatra::SwaggerExposer::SwaggerInvalidException
    end

    it 'must fail with an unknown value at the top level' do
      e = must_raise_swag(-> { new_info({:unknwown => :something})})
      e.message.must_match /#{'unknown'}/
    end

    it 'must fail with an unknown value at the second level' do
      e = must_raise_swag(-> { new_info({:contact => {:unknwown => :something}})})
      e.message.must_match /#{'unknown'}/
    end

    it 'must fail when a top level hash value has a wrong type' do
      e = must_raise_swag(-> { new_info({:contact => []})})
      e.message.must_match /#{'contact'}/
      e = must_raise_swag(-> { new_info({:contact => 'plop'})})
      e.message.must_match /#{'contact'}/
    end

    it 'must fail when a top level string value has a wrong type' do
      e = must_raise_swag(-> { new_info({:title => []})})
      e.message.must_match /#{'title'}/
      e = must_raise_swag(-> { new_info({:title => {}})})
      e.message.must_match /#{'title'}/
    end

    it 'must fail when a second level string value has a wrong type' do
      e = must_raise_swag(-> { new_info({:contact => {:name => []}})})
      e.message.must_match /#{'name'}/
      e = must_raise_swag(-> { new_info({:contact => {:name => {}}})})
      e.message.must_match /#{'name'}/
    end

    it 'must return the values' do
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
