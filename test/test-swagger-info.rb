require_relative 'minitest-helper'
require_relative '../lib/sinatra/swagger-exposer/swagger-info'

class TestVersion < Minitest::Test

  describe Sinatra::SwaggerExposer::SwaggerInfo do

    it 'must fail with an unknown value at the top level' do
      e = -> { Sinatra::SwaggerExposer::SwaggerInfo.new({:unknwown => :something})}.must_raise Sinatra::SwaggerExposer::SwaggerInvalidException
      e.message.must_match /#{'unknown'}/
    end

    it 'must fail with an unknown value at the second level' do
      e = -> { Sinatra::SwaggerExposer::SwaggerInfo.new({:contact => {:unknwown => :something}})}.must_raise Sinatra::SwaggerExposer::SwaggerInvalidException
      e.message.must_match /#{'unknown'}/
    end

    it 'must fail when a top level hash value has a wrong type' do
      e = -> { Sinatra::SwaggerExposer::SwaggerInfo.new({:contact => []})}.must_raise Sinatra::SwaggerExposer::SwaggerInvalidException
      e.message.must_match /#{'contact'}/
      e = -> { Sinatra::SwaggerExposer::SwaggerInfo.new({:contact => 'plop'})}.must_raise Sinatra::SwaggerExposer::SwaggerInvalidException
      e.message.must_match /#{'contact'}/
    end

    it 'must fail when a top level string value has a wrong type' do
      e = -> { Sinatra::SwaggerExposer::SwaggerInfo.new({:title => []})}.must_raise Sinatra::SwaggerExposer::SwaggerInvalidException
      e.message.must_match /#{'title'}/
      e = -> { Sinatra::SwaggerExposer::SwaggerInfo.new({:title => {}})}.must_raise Sinatra::SwaggerExposer::SwaggerInvalidException
      e.message.must_match /#{'title'}/
    end

    it 'must fail when a second level string value has a wrong type' do
      e = -> { Sinatra::SwaggerExposer::SwaggerInfo.new({:contact => {:name => []}})}.must_raise Sinatra::SwaggerExposer::SwaggerInvalidException
      e.message.must_match /#{'name'}/
      e = -> { Sinatra::SwaggerExposer::SwaggerInfo.new({:contact => {:name => {}}})}.must_raise Sinatra::SwaggerExposer::SwaggerInvalidException
      e.message.must_match /#{'name'}/
    end

    it 'must return the values' do
      content = {:contact => {:name => 'me'}, :version => '1.0'}
      Sinatra::SwaggerExposer::SwaggerInfo.new(content).to_swagger.must_equal content
    end

    it 'must return the values with keys as symbols' do
      content_string = {'contact' => {'name' => 'me'}, 'version' => '1.0'}
      content_symbol = {:contact => {:name => 'me'}, :version => '1.0'}
      Sinatra::SwaggerExposer::SwaggerInfo.new(content_string).to_swagger.must_equal content_symbol
    end

    it 'must return nil when there is no property' do
      Sinatra::SwaggerExposer::SwaggerInfo.new({}).to_swagger.must_be_nil
    end


  end

end
