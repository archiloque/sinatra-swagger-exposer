require 'sinatra/base'
require 'json'

require_relative 'swagger-endpoint'
require_relative 'swagger-endpoint-parameter'
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
      app.set :swagger_current_endpoint_parameters, {}
      app.set :swagger_current_endpoint_responses, {}
      app.set :swagger_types, {}
      declare_swagger_endpoints(app)
    end

    def self.declare_swagger_endpoints(app)
      app.endpoint_summary 'The swagger endpoint'
      app.endpoint_tags 'swagger'
      app.get '/swagger_doc.json' do
        swagger_content = ::Sinatra::SwaggerExposer::SwaggerContentCreator.new(
            settings.respond_to?(:swagger_info) ? settings.swagger_info : nil,
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
      set_if_type_and_not_exist(summary, :summary, String)
    end

    # Provide a path
    def endpoint_path(path)
      set_if_type_and_not_exist(path, :path, String)
    end

    # Provide a description for the endpoint
    def endpoint_description(description)
      set_if_type_and_not_exist(description, :description, String)
    end

    # Provide tags for the endpoint
    def endpoint_tags(*tags)
      set_if_type_and_not_exist(tags, :tags, nil)
    end

    # Define parameter for the endpoint
    def endpoint_parameter(name, description, how_to_pass, required, type, params = {})
      parameters = settings.swagger_current_endpoint_parameters
      check_if_not_duplicate(name, parameters, 'Parameter')
      parameters[name] = SwaggerEndpointParameter.new(
          name,
          description,
          how_to_pass,
          required,
          type,
          params,
          settings.swagger_types.keys)
    end

    # Define fluent endpoint dispatcher
    def endpoint(params)
      if params[:summary]
        endpoint_summary params[:summary]
      end
      if params[:description]
        endpoint_description params[:description]
      end
      if params[:response]
        endpoint_response *params[:response]
      end
      if params[:tags]
        endpoint_tags *params[:tags]
      end
      if params[:parameters]
        params[:parameters].each do |param, args|
          endpoint_parameter param, *args
        end
      end

    end


    # General information
    def general_info(params)
      set :swagger_info, SwaggerInfo.new(params)
    end

    # Declare a type
    def type(name, params)
      types = settings.swagger_types
      if types.key? name
        raise SwaggerInvalidException.new("Type [#{name}] already exist with value #{types[name]}")
      end
      types[name] = SwaggerType.new(name, params, settings.swagger_types.keys)
    end

    # Declare a response
    def endpoint_response(code, type = nil, description = nil)
      responses = settings.swagger_current_endpoint_responses
      check_if_not_duplicate(code, responses, 'Response')
      responses[code] = SwaggerEndpointResponse.new(type, description, settings.swagger_types.keys)
    end

    def route(verb, path, options = {}, &block)
      if verb == 'HEAD'
        super(verb, path, options, &block)
      else
        request_preprocessor = process_endpoint(verb.downcase, path, options)
        super(verb, path, options) do |*params|
          request_preprocessor.run(self, params, &block)
        end
      end
    end

    private

    # Call for each endpoint declaration
    # @return [SwaggerRequestPreprocessor]
    def process_endpoint(type, path, opts)
      current_endpoint_info = settings.swagger_current_endpoint_info
      current_endpoint_parameters = settings.swagger_current_endpoint_parameters
      current_endpoint_responses = settings.swagger_current_endpoint_responses
      endpoint = SwaggerEndpoint.new(
          type,
          path,
          current_endpoint_parameters.values,
          current_endpoint_responses.clone,
          current_endpoint_info[:summary],
          current_endpoint_info[:description],
          current_endpoint_info[:tags],
          current_endpoint_info[:path])
      settings.swagger_endpoints << endpoint
      current_endpoint_info.clear
      current_endpoint_parameters.clear
      current_endpoint_responses.clear
      endpoint.request_preprocessor
    end

    def set_if_type_and_not_exist(value, name, type)
      if type
        unless value.is_a? type
          raise SwaggerInvalidException.new("#{name} [#{value}] should be a #{type.to_s.downcase}")
        end
      end
      if settings.swagger_current_endpoint_info.key? name
        raise SwaggerInvalidException.new("#{name} with value [#{value}] already defined: [#{settings.swagger_current_endpoint_info[name]}]")
      end
      settings.swagger_current_endpoint_info[name] = value
    end

    def check_if_not_duplicate(key, values, name)
      if values.key? key
        raise SwaggerInvalidException.new("#{name} already exist for #{key} with value [#{values[key]}]")
      end
    end

  end

end
