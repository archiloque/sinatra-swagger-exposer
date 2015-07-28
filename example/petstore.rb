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
                        :maxLength => 2048,
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
  type 'Cat', {
                # Not yet supported in swagger-ui, see https://github.com/swagger-api/swagger-js/issues/188
                :extends => 'Pet',
                :properties => {
                    :fluffy => {
                        :type => TrueClass,
                        :description => 'is this cat fluffy ?',
                        :example => true,
                        :default => false
                    },
                },
            }

  type 'CatRoot',
       {
           :properties => {
               :cat => {
                   :type => 'Cat',
                   :description => 'A cat',
               }
           },
           :required => [:cat],
       }


  endpoint_summary 'Finds all the pets'
  endpoint_description 'Returns all pets from the system that the user has access to'
  endpoint_tags 'Pets'
  endpoint_response 200, ['Pet'], 'Standard response'
  endpoint_parameter :size, 'The number of pets to return', :query, false, Integer,
                     {
                         :example => 100,
                         :default => 20, # If the caller send no value the default value will be set in the params
                         :maximum => 100,
                         :minimum => 0,
                         :exclusiveMinimum => true,
                     }
  get '/pet' do
    content_type :json
    [].to_json
  end

  endpoint_summary 'Create a pet'
  endpoint_tags 'Pets'
  endpoint_response 200, 'Pet', 'Standard response'
  endpoint_parameter :name, 'The pet name', :body, true, String, {
                              :minLength => 1,
                              :maxLength => 255,
                          }
  endpoint_parameter :status, 'The pet status', :body, false, String
  post '/pet' do
    # As some parameters are in the body
    # the parsed param body is available in params['parsed_body']
    name = params['parsed_body']['name']

    # Create the pet ...
    content_type :json
    {:id => 0, :name => name}.to_json
  end

  endpoint_summary 'Finds all the cats'
  endpoint_description 'Returns all cats from the system that the user has access to'
  endpoint_tags 'Cats'
  endpoint_response 200, ['Cat'], 'Standard response'
  endpoint_parameter :size, 'The number of cats to return', :query, false, Integer,
                     {
                         :example => 100,
                         :default => 20, # If the caller send no value the default value will be set in the params
                         :maximum => 100,
                         :minimum => 0,
                         :exclusiveMinimum => true,
                     }
  get '/cat' do
    content_type :json
    [].to_json
  end

  endpoint_summary 'Finds a pet by its id'
  endpoint_description 'Finds a pet by its id, or 404 if the user does not have access to the pet'
  endpoint_tags 'Pets'
  endpoint_response 200, 'Pet', 'Standard response'
  endpoint_response 404, 'Error', 'Pet not found'
  endpoint_parameter :id, 'The pet id', :path, true, Integer, # Will fail if a non-numerical value is used
                     {
                         :example => 1234,
                     }
  endpoint_path '/pet/{id}'
  get %r{/pet/(\d+)} do |id|
    content_type :json
    [404, {:code => 404, :message => 'Pet not found'}.to_json]
  end

  endpoint_summary 'Get a pet image'
  endpoint_description 'Get a pet image from its id'
  endpoint_tags 'Pets'
  endpoint_produces 'image/gif', 'application/json'
  endpoint_response 200, 'file', 'Standard response'
  endpoint_response 404, 'Error', 'Pet not found'
  endpoint_parameter :id, 'The pet id', :path, true, Integer, # Will fail if a non-numerical value is used
                     {
                         :example => 1234,
                     }
  endpoint_path '/pet/{id}/image'
  get %r{/pet/(\d+)} do |id|
    content_type :json
    [404, {:code => 404, :message => 'Pet not found'}.to_json]
  end

  endpoint_summary 'Create a cat'
  endpoint_tags 'Cats'
  endpoint_response 200, 'CatRoot', 'Standard response'
  endpoint_parameter :cat, 'The cat', :body, true, 'CatRoot'
  post '/cat' do
    # As some parameters are in the body
    # the parsed param body is available in params['parsed_body']
    name = params['parsed_body']['cat']['name']

    # Create the cat ...
    content_type :json
    {:cat => {:id => 0, :name => name}}.to_json
  end


  # See https://github.com/britg/sinatra-cross_origin/issues/18
  options '*' do
    response.headers['Allow'] = 'HEAD,GET,PUT,POST,DELETE,OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'
    200
  end

end

