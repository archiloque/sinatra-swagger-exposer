require 'sinatra/base'
require 'json'

require_relative 'configuration/swagger-endpoint'
require_relative 'configuration/swagger-endpoint-parameter'
require_relative 'configuration/swagger-endpoint-response'
require_relative 'configuration/swagger-response-headers'
require_relative 'configuration/swagger-info'
require_relative 'configuration/swagger-types'
require_relative 'swagger-content-creator'
require_relative 'swagger-invalid-exception'
require_relative 'swagger-preprocessor-creator'

module Sinatra

  # Expose swagger API from your Sinatra app
  module SwaggerExposer

    def self.registered(app)
      app.set :swagger_endpoints, []
      app.set :swagger_current_endpoint_info, {}
      app.set :swagger_current_endpoint_parameters, {}
      app.set :swagger_current_endpoint_responses, {}

      swagger_types = Sinatra::SwaggerExposer::Configuration::SwaggerTypes.new
      app.set :swagger_types, swagger_types

      response_headers = Sinatra::SwaggerExposer::Configuration::SwaggerResponseHeaders.new
      app.set :swagger_response_headers, response_headers

      app.set :swagger_preprocessor_creator, Sinatra::SwaggerExposer::SwaggerPreprocessorCreator.new(swagger_types)
      declare_swagger_endpoints(app)
    end

    def self.declare_swagger_endpoints(app)
      app.endpoint_summary 'The swagger endpoint'
      app.endpoint_tags 'swagger'
      app.get '/swagger_doc.json' do
        swagger_content = Sinatra::SwaggerExposer::SwaggerContentCreator.new(
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
      set_if_not_exist(tags, :tags)
    end

    # Provide produces params for the endpoint
    def endpoint_produces(*produces)
      set_if_not_exist(produces, :produces)
    end

    # Define parameter for the endpoint
    def endpoint_parameter(name, description, how_to_pass, required, type, params = {})
      parameters = settings.swagger_current_endpoint_parameters
      check_if_not_duplicate(name, parameters, 'Parameter')
      parameters[name] = Sinatra::SwaggerExposer::Configuration::SwaggerEndpointParameter.new(
          name,
          description,
          how_to_pass,
          required,
          type,
          params,
          settings.swagger_types.types_names)
    end

    # Define fluent endpoint dispatcher
    # @param params [Hash] the parameters
    def endpoint(params)
      params.each_pair do |param_name, param_value|
        case param_name
          when :summary
            endpoint_summary param_value
          when :description
            endpoint_description param_value
          when :tags
            endpoint_tags *param_value
          when :produces
            endpoint_produces *param_value
          when :path
            endpoint_path param_value
          when :parameters
            param_value.each do |param, args_param|
              endpoint_parameter param, *args_param
            end
          when :responses
            param_value.each do |code, args_response|
              endpoint_response code, *args_response
            end
          else
            raise SwaggerInvalidException.new("Invalid endpoint parameter [#{param_name}]")
        end
      end
    end

    # General information
    def general_info(params)
      set :swagger_info, Sinatra::SwaggerExposer::Configuration::SwaggerInfo.new(params)
    end

    # Declare a type
    def type(name, params)
      settings.swagger_types.add_type(name, params)
    end

    # Declare a response header
    def response_header(name, type, description)
      settings.swagger_response_headers.add_response_header(name, type, description)
    end

    # Declare a response
    def endpoint_response(code, type = nil, description = nil, headers = [])
      responses = settings.swagger_current_endpoint_responses
      check_if_not_duplicate(code, responses, 'Response')
      responses[code] = Sinatra::SwaggerExposer::Configuration::SwaggerEndpointResponse.new(
          type,
          description,
          settings.swagger_types.types_names,
          headers,
          settings.swagger_response_headers
      )
    end

    def route(verb, path, options = {}, &block)
      no_swagger = options[:no_swagger]
      options.delete(:no_swagger)
      if (verb == 'HEAD') || no_swagger
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
      endpoint = Sinatra::SwaggerExposer::Configuration::SwaggerEndpoint.new(
          type,
          path,
          current_endpoint_parameters.values,
          current_endpoint_responses.clone,
          current_endpoint_info[:summary],
          current_endpoint_info[:description],
          current_endpoint_info[:tags],
          current_endpoint_info[:path],
          current_endpoint_info[:produces])
      settings.swagger_endpoints << endpoint
      current_endpoint_info.clear
      current_endpoint_parameters.clear
      current_endpoint_responses.clear
      settings.swagger_preprocessor_creator.create_endpoint_processor(endpoint)
    end

    def set_if_not_exist(value, name)
      if settings.swagger_current_endpoint_info.key? name
        raise SwaggerInvalidException.new("#{name} with value [#{value}] already defined: [#{settings.swagger_current_endpoint_info[name]}]")
      end
      settings.swagger_current_endpoint_info[name] = value
    end

    def set_if_type_and_not_exist(value, name, type)
      unless value.is_a? type
        raise SwaggerInvalidException.new("#{name} [#{value}] should be a #{type.to_s.downcase}")
      end
      set_if_not_exist(value, name)
    end

    def check_if_not_duplicate(key, values, name)
      if values.key? key
        raise SwaggerInvalidException.new("#{name} already exist for #{key} with value [#{values[key]}]")
      end
    end

  end

end
