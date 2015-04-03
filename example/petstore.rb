require 'sinatra/base'
require_relative '../lib/sinatra/swagger-exposer/swagger-exposer'
require 'json'

class Petstore < Sinatra::Base

  set :logging, true

  register Sinatra::SwaggerExposer

  swagger_info(
      {
          :version => '1.0.0',
          :title => 'Swagger Petstore',
          :description => 'A sample API that uses a petstore as an example to demonstrate features in the swagger-2.0 specification',
          :termsOfService => 'http://swagger.io/terms/',
          :contact => {:name => 'Swagger API Team',
                       :email => 'apiteam@swagger.io',
                       :url => 'http://swagger.io'
          },
          :license => {
              :name => 'Apache 2.0',
              :url => 'http://github.com/gruntjs/grunt/blob/master/LICENSE-MIT'
          }
      }
  )

  type 'Pet',
       {
           :required => [
               'id',
               'name'
           ],
           :properties => {
               :id => {
                   :type => Integer,
                   :format => 'int64',
               },
               :name => {
                   :type => String,
                   :example => 'doggie',
                   :description => 'The pet name'
               },
               :photoUrls => {
                   :type => Array,
                   :items => {
                       :type => String,
                   },
               },
               :tags => {
                   :type => 'array',
                   :items => {
                       :type => String,
                   },
                   :description => 'The pet\'s tags'
               },
               :status => {
                   :type => String,
                   :description => 'pet status in the store',
                   :example => 'sleepy',
               },
           },
       }

  endpoint_summary 'Finds all the pets'
  endpoint_description 'Returns all pets from the system that the user has access to'
  endpoint_response 200, 'Standard response', 'Pet', :type => Array
  get '/pets' do
    content_type :json
    [].to_json
  end

end

