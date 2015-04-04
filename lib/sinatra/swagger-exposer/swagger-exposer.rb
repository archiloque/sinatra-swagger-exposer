require 'sinatra/base'
require 'json'

require_relative 'swagger-endpoint'
require_relative 'swagger-endpoint-response'
require_relative 'swagger-info'
require_relative 'swagger-invalid-exception'
require_relative 'swagger-type'

require_relative 'swagger-content-creator'

module Sinatra

  # Expose swagger API from your Sinatra app
  module SwaggerExposer

    def self.registered(app)
      app.set :swagger_endpoints, []
      app.set :swagger_current_endpoint_info, {}
      app.set :swagger_current_endpoint_responses, {}
      app.set :swagger_types, {}


      # Declare the swagger endpoints
      app.endpoint_summary 'The swagger endpoint'
      app.endpoint_tags 'swagger'
      app.get '/swagger_doc.json' do
        swagger_content = ::Sinatra::SwaggerExposer::SwaggerContentCreator.new(
            settings.swagger_info,
            settings.swagger_types,
            settings.swagger_endpoints
        ).to_swagger
        content_type :json
        swagger_content.to_json
      end

      app.endpoint_summary 'Option method for the swagger endpoint, useful for some CORS stuff'
      app.endpoint_tags 'swagger'
      app.options '/swagger_doc.json' do
        200
      end

    end

    # Provide a summary for the endpoint
    def endpoint_summary(summary)
      settings.swagger_current_endpoint_info[:summary] = summary
    end

    # Provide a description for the endpoint
    def endpoint_description(description)
      settings.swagger_current_endpoint_info[:description] = description
    end

    # Provide tags for the endpoint
    def endpoint_tags(*tags)
      settings.swagger_current_endpoint_info[:tags] = tags
    end

    # General information
    def swagger_info(params)
      set :swagger_info, SwaggerInfo.new(params)
    end

    # Declare a type
    def type(name, params)
      types = settings.swagger_types
      if types.key? name
        raise "Type [#{name}] already exist with value #{types[name]}"
      end
      types[name] = SwaggerType.new(name, params)
    end

    # Declare a response
    def endpoint_response(code, description = nil, type = nil, params = nil)
      responses = settings.swagger_current_endpoint_responses
      if responses.key? code
        raise SwaggerInvalidException.new("Response code [#{code}] already exist")
      end
      responses[code] = SwaggerEndpointResponse.new(description, type, settings.swagger_types.keys)
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
      current_endpoint_info = settings.swagger_current_endpoint_info
      current_endpoint_responses = settings.swagger_current_endpoint_responses
      endpoint_path = args[0]
      settings.swagger_endpoints << SwaggerEndpoint.new(
          type,
          endpoint_path,
          current_endpoint_responses.clone,
          current_endpoint_info[:summary],
          current_endpoint_info[:description],
          current_endpoint_info[:tags])
      current_endpoint_info.clear
      current_endpoint_responses.clear
    end

  end

end
