require_relative '../minitest-helper'
require_relative '../test-utilities'

require_relative '../../lib/sinatra/swagger-exposer/configuration/swagger-info'

class TestSwaggerInfo < Minitest::Test

  describe Sinatra::SwaggerExposer::Configuration::SwaggerInfo do

    include TestUtilities

    it 'must fail with a unknown values' do
      must_raise_swag_and_equal(
      -> { new_info({:unknown => :something}) },
      'Unknown property [unknown] for info, possible values are version, title, description, termsOfService, contact, license'
      )
      must_raise_swag_and_equal(
      -> { new_info({:contact => {:unknown => :something}}) },
      'Unknown property [unknown] for info, possible values are name, email, url'
      )
    end

    it 'must fail when a top level hash value has a wrong type' do
      must_raise_swag_and_equal(
      -> { new_info({:contact => []}) },
      'Property [contact] value [[]] should be a Hash for info: {:contact=>[]}'
      )
      must_raise_swag_and_equal(
      -> { new_info({:contact => 'plop'}) },
      'Property [contact] value [plop] should be a Hash for info: {:contact=>"plop"}'
      )
    end

    it 'must fail when a top level string value has a wrong type' do
      must_raise_swag_and_equal(
      -> { new_info({:title => []}) },
      'Property [title] value [[]] should be a String for info: {:title=>[]}'
      )
      must_raise_swag_and_equal(
      -> { new_info({:title => {}}) },
      'Property [title] value [{}] should be a String for info: {:title=>{}}'
      )
    end

    it 'must fail when a second level string value has a wrong type' do
      must_raise_swag_and_equal(
      -> { new_info({:contact => {:name => []}}) },
      'Property [name] value [[]] should be a String for info: {:contact=>{:name=>[]}}'
      )
      must_raise_swag_and_equal(
      -> { new_info({:contact => {:name => {}}}) },
      'Property [name] value [{}] should be a String for info: {:contact=>{:name=>{}}}'
      )
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

    it 'must answer to to_s' do
      JSON.parse(new_info({:version => '1.0'}).to_s).must_equal({'version' => '1.0'})
    end


  end

end
