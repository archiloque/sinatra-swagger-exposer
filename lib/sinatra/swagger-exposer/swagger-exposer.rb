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
require_relative 'swagger-request-processor-creator'

module Sinatra

  # Expose swagger API from your Sinatra app
  module SwaggerExposer

    # Called when we register the extension
    # @param app [Sinatra::Base]
    def self.registered(app)
      app.set :result_validation, (ENV['RACK_ENV'] != 'production')
      app.set :swagger_endpoints, []
      app.set :swagger_current_endpoint_info, {}
      app.set :swagger_current_endpoint_parameters, {}
      app.set :swagger_current_endpoint_responses, {}

      swagger_types = Sinatra::SwaggerExposer::Configuration::SwaggerTypes.new
      app.set :swagger_types, swagger_types

      response_headers = Sinatra::SwaggerExposer::Configuration::SwaggerResponseHeaders.new
      app.set :swagger_response_headers, response_headers

      app.set :swagger_processor_creator, Sinatra::SwaggerExposer::SwaggerProcessorCreator.new(swagger_types)
      declare_swagger_endpoint(app)
    end

    # Declare the endpoint to serve the swagger content
    # @param app [Sinatra::Base]
    def self.declare_swagger_endpoint(app)
      app.endpoint_summary 'The swagger endpoint'
      app.endpoint_tags 'swagger'
      app.endpoint_response 200
      app.get('/swagger_doc.json') do
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
      app.endpoint_response 200
      app.endpoint_produces 'text/plain;charset=utf-8'
      app.options('/swagger_doc.json') do
        content_type :text
        200
      end
    end

    # Provide a summary for the endpoint
    # @param summary [String]
    def endpoint_summary(summary)
      set_if_type_and_not_exist(summary, :summary, String)
    end

    # Provide a path
    # @param path [String]
    def endpoint_path(path)
      set_if_type_and_not_exist(path, :path, String)
    end

    # Provide a description for the endpoint
    # @param description [String]
    def endpoint_description(description)
      set_if_type_and_not_exist(description, :description, String)
    end

    # Provide tags for the endpoint
    # @param tags [Array<String>]
    def endpoint_tags(*tags)
      set_if_not_exist(tags, :tags)
    end

    # Provide produces params for the endpoint
    # @param produces [Array<String>] the response types
    def endpoint_produces(*produces)
      set_if_not_exist(produces, :produces)
    end

    # Provide an operationId for the endpoint
    # @param operation_id, [String] the operationId
    def endpoint_operation_id(operation_id)
      set_if_type_and_not_exist(operation_id, :operation_id, String)
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
          when :operation_id
            endpoint_operation_id param_value
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
    # @param code [Integer] the response code
    # @param type the type
    # @param description [String] the description
    # @param headers [Array<String>] the headers names
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

    # Override Sinatra route method
    def route(verb, path, options = {}, &block)
      no_swagger = options[:no_swagger]
      options.delete(:no_swagger)
      if (verb == 'HEAD') || no_swagger
        super(verb, path, options, &block)
      else
        request_processor = create_request_processor(verb.downcase, path, options)
        super(verb, path, options) do |*params|
          response = catch(:halt) do
            request_processor.run(self, params, &block)
          end
          if settings.result_validation
            begin
              # Inspired from Sinatra#invoke
              if (Fixnum === response) or (String === response)
                response = [response]
              end
              if (Array === response) and (Fixnum === response.first)
                response_for_validation = response.dup
                response_status = response_for_validation.shift
                response_body = response_for_validation.pop
                response_headers = (response_for_validation.pop || {}).merge(self.response.header)
                response_content_type = response_headers['Content-Type']
                request_processor.validate_response(response_body, response_content_type, response_status)
              elsif response.respond_to? :each
                request_processor.validate_response(response.first.dup, self.response.header['Content-Type'], 200)
              end
            rescue Sinatra::SwaggerExposer::SwaggerInvalidException => e
              content_type :json
              throw :halt, [400, {:code => 400, :message => e.message}.to_json]
            end
          end
          throw :halt, response
        end
      end
    end

    private

    # Call for each endpoint declaration
    # @return [Sinatra::SwaggerExposer::Processing::SwaggerRequestProcessor]
    def create_request_processor(type, path, opts)
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
        current_endpoint_info[:produces],
        current_endpoint_info[:operation_id])
      settings.swagger_endpoints << endpoint
      current_endpoint_info.clear
      current_endpoint_parameters.clear
      current_endpoint_responses.clear
      settings.swagger_processor_creator.create_request_processor(endpoint)
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

    # Check if a value does not exist in a hash and throw an Exception
    # @param key the key to validate
    # @param values [Hash] the existing keys
    # @param name [String] the valud name for the error message
    def check_if_not_duplicate(key, values, name)
      if values.key? key
        raise SwaggerInvalidException.new("#{name} already exist for #{key} with value [#{values[key]}]")
      end
    end

  end

end
