require 'sinatra/base'
require 'json'

require_relative 'swagger-content-creator'
require_relative 'swagger-info-processor'
require_relative 'swagger-response-processor'

module Sinatra

  # Expose swagger API from your Sinatra app
  module SwaggerExposer

    def self.registered(app)
      app.set :swagger_endpoints, []
      app.set :swagger_current_endpoint, {}
      app.set :swagger_types, {}

      # Declare the swagger endpoint
      app.get '/swagger_doc.json' do
        result_endpoints = ::Sinatra::SwaggerExposer::SwaggerContentCreator.new(app).create_content(
            settings.swagger_types,
            settings.swagger_endpoints,
            settings.swagger_info
        )
        content_type :json
        result_endpoints.to_json
      end
    end

    # Provide a summary for the endpoint
    def endpoint_summary(text)
      settings.swagger_current_endpoint[:summary] = text
    end

    # Provide a description for the endpoint
    def endpoint_description(text)
      settings.swagger_current_endpoint[:description] = text
    end

    # General information
    def swagger_info(params)
      set :swagger_info, ::Sinatra::SwaggerExposer::SwaggerInfoValidator.new(self).validate(params, 'info', params)
    end

    # Declare a type
    def type(name, params)
      types = settings.swagger_types
      if types.key? name
        raise "Type [#{name}] already exist with value #{types[name]}"
      end
      types[name] = params
    end

    # Declare a response
    def endpoint_response(code, description, type, params = nil)
      ::Sinatra::SwaggerExposer::SwaggerResponseValidator.new(self).validate(
          settings.swagger_current_endpoint,
          settings.swagger_types,
          code,
          description,
          type,
          params
      )
    end

    def delete(*args, &block)
      process_endpoint('delete', args)
      super(*args, &block)
    end

    def get(*args, &block)
      process_endpoint('get', args)
      super(*args, &block)
    end

    def head(*args, &block)
      process_endpoint('head', args)
      super(*args, &block)
    end

    def link(*args, &block)
      process_endpoint('link', args)
      super(*args, &block)
    end

    def options(*args, &block)
      process_endpoint('options', args)
      super(*args, &block)
    end

    def patch(*args, &block)
      process_endpoint('patch', args)
      super(*args, &block)
    end

    def post(*args, &block)
      process_endpoint('post', args)
      super(*args, &block)
    end

    def put(*args, &block)
      process_endpoint('put', args)
      super(*args, &block)
    end

    def unlink(*args, &block)
      process_endpoint('unlink', args)
      super(*args, &block)
    end

    private

    # Call for each endpoint declaration
    def process_endpoint(type, args)
      current_endpoint = settings.swagger_current_endpoint
      current_endpoint[:type] = type
      current_endpoint[:path] = args[0]
      if logging?
        $stderr.puts "Swagger: found new endpoint #{current_endpoint}"
      end
      settings.swagger_endpoints << current_endpoint.clone
      settings.swagger_current_endpoint.clear
    end

  end

end
