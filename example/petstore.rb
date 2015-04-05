require 'sinatra/base'
require 'json'
require 'sinatra/cross_origin'

require_relative '../lib/sinatra/swagger-exposer/swagger-exposer'

class Petstore < Sinatra::Base

  set :logging, true

  register Sinatra::CrossOrigin
  set :allow_origin, :any
  enable :cross_origin

  register Sinatra::SwaggerExposer

  general_info(
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

  type 'Error', {
                  :required => [:code, :message],
                  :properties => {
                      :code => {
                          :type => Integer,
                          :example => 404,
                          :description => 'The error code',
                      },
                      :message => {
                          :type => String,
                          :example => 'Pet not found',
                          :description => 'The error message',
                      },
                  },
              }


  type 'Pet', {
                :required => [:id, :name],
                :properties => {
                    :id => {
                        :type => Integer,
                        :format => 'int64',
                    },
                    :name => {
                        :type => String,
                        :example => 'doggie',
                        :description => 'The pet name',
                    },
                    :photoUrls => {
                        :type => [String],
                    },
                    :tags => {
                        :type => [String],
                        :description => 'The pet\'s tags',
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
  endpoint_tags 'Pets'
  endpoint_response 200, ['Pet'], 'Standard response'
  get '/pets' do
    content_type :json
    [].to_json
  end

  endpoint_summary 'Finds a pet by its id'
  endpoint_description 'Finds a pet by its id, or 404 if the user does not have access to the pet'
  endpoint_tags 'Pets'
  endpoint_response 200, 'Pet', 'Standard response'
  endpoint_response 404, 'Error', 'Pet not found'
  endpoint_parameter :id, 'The pet id', :path, true, String
                 {
                     :example => 'AMZ',
                 }
  get '/pets/:id' do
    content_type :json
    [404, {:code => 404, :message => 'Pet not found'}]
  end

end

