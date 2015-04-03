require 'sinatra/base'
require 'json'

module Sinatra

  # Expose swagger API from your Sinatra app
  module SwaggerExposer

    class SwaggerContentCreator

      def initialize(app)
        @app = app
      end

      def log(message)
        if @app.logging?
          $stderr.puts message
        end
      end

      def create_swagger_content(types, endpoints, info)
        result_endpoints = {}

        # swagger need the endpoints to be grouped by path
        endpoints_by_path = endpoints.group_by { |endpoint| endpoint[:path] }
        endpoints_by_path.keys.sort.each do |path|
          endpoints = endpoints_by_path[path]

          result_endpoints_for_path = {}
          endpoints.each do |endpoint|
            result_endpoint = create_swagger_endpoint(endpoint)
            result_endpoints_for_path[endpoint[:type]] = result_endpoint
          end

          result_endpoints[path] = result_endpoints_for_path
        end
        result_types = {}
        types.each_pair do |name, value|
          result_types[name] = create_swagger_type(value)
        end

        result = {
            swagger: '2.0',
            consumes: [
                'application/json'
            ],
            produces: [
                'application/json'
            ],
            paths: result_endpoints,
            definitions: result_types,
        }
        if info
          result[:info] = info
        end

        result
      end

      SWAGGER_TYPE_KNOW_PROPERTIES = [:required, :example, :properties]

      def create_swagger_type(type)
        result_type = {}

        if type.key? :properties
          result_properties = {}
          type[:properties].each_pair do |property_name, property_info|
            result_property = create_swagger_type_property(property_name, property_info)
            if result_property
              result_properties[property_name] = result_property
            end
          end
          unless result_properties.empty?
            result_type[:properties] = result_properties
          end
        end

        (SWAGGER_TYPE_KNOW_PROPERTIES - [:properties]).each do |property_key|
          if type.key? property_key
            result_type[property_key] = type[property_key]
          end
        end

        type.each_pair do |property_name, property_value|
          unless SWAGGER_TYPE_KNOW_PROPERTIES.include? property_name
            log "Swagger: unknown property [#{property_name}] for [#{property_name}]: #{type}"
          end
        end

      end

      SWAGGER_TYPE_PROPERTIES_KNOW_PROPERTIES = [:type, :format, :example, :description, :items]

      def create_swagger_type_property(property_name, property_info)
        result = {}
        SWAGGER_TYPE_PROPERTIES_KNOW_PROPERTIES.each do |known_property|
          if property_info.key? known_property
            property_value = property_info[known_property]
            if property_value.is_a? Class
              property_value = property_value.to_s.downcase
            elsif property_value.is_a? Hash
              if known_property != :items
                log "Swagger: property is a hash [#{property_value}] for a type that shouldn't be [#{known_property}] for [#{property_name}]: #{property_info}"
              end
              property_value.each_pair do |key, value|
                if value.is_a? Class
                  property_value[key] = value.to_s.downcase
                end
              end
            end
            result[known_property] = property_value
          end
        end
        if result[:items] && (result[:type] != 'array')
          log "Swagger: specifing an items property [#{result[:items]}] for a non array type [#{result[:type]}] for [#{property_name}]: #{property_info}"
        end
        property_info.each_pair do |property_name, property_value|
          unless SWAGGER_TYPE_PROPERTIES_KNOW_PROPERTIES.include? property_name
            log "Swagger: unknown property [#{property_name}] for [#{property_name}]: #{property_info}"
          end
        end

        result.empty? ? nil : result
      end

      def create_swagger_endpoint(endpoint)
        result_endpoint = {
            produces: ['application/json']
        }
        [:summary, :description].each do |property_name|
          if endpoint[property_name]
            result_endpoint[property_name] = endpoint[property_name]
          end
        end
        responses = endpoint[:responses]
        if responses && (!responses.empty?)
          result_responses = {}
          responses.each_pair do |code, content|
            result_response = {
                :description => content[:description],
            }
            if content[:params] && content[:params][:type]
              result_response[:schema] = {
                  :type => content[:params][:type],
                  :items => {
                      '$ref' => "#/definitions/#{content[:type]}",
                  }
              }
            else
              result_response[:schema] = {
                  '$ref' => "#/definitions/#{content[:type]}",
              }
            end
            result_responses[code] = result_response
          end
          result_endpoint[:responses] = result_responses
        end
        result_endpoint
      end

    end

    def self.registered(app)

      app.set :swagger_endpoints, []
      app.set :swagger_current_endpoint, {}
      app.set :swagger_types, {}

      # Declare the swagger endpoint
      app.get '/swagger_doc.json' do
        result_endpoints = ::Sinatra::SwaggerExposer::SwaggerContentCreator.new(app).create_swagger_content(
            settings.swagger_types,
            settings.swagger_endpoints,
            settings.swagger_info
        )
        content_type :json
        result_endpoints.to_json
      end
    end

    # Provide a summary for the endpoint
    def summary(text)
      settings.swagger_current_endpoint[:summary] = text
    end

    # Provide a description for the endpoint
    def description(text)
      settings.swagger_current_endpoint[:description] = text
    end

    # Known fields for the info field
    INFO_FIELDS = {
        :version => String,
        :title => String,
        :description => String,
        :termsOfService => String,
        :contact => {:name => String, :email => String, :url => String, },
        :license => {:name => String, :url => String, },
    }

    # General information
    def swagger_info(params)
      set :swagger_info, validate_params(params, INFO_FIELDS, 'info', params)
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
    def response(code, description, type, params = nil)
      current_endpoint = settings.swagger_current_endpoint
      unless current_endpoint.key? :responses
        current_endpoint[:responses] = {}
      end
      if current_endpoint[:responses].key? code
        raise "Response [#{code}] already exist with value #{current_endpoint[:responses][code]}"
      end
      if type.is_a?(String) && (!settings.swagger_types.key?(type))
        raise "Unknown type [#{type}], registered types are #{settings.swagger_types.keys.join(', ')}"
      end

      current_response = {
          :description => description,
          :type => type,
      }

      if params
        params.each_pair do |param_key, param_value|
          unless [:type].include? param_key
            raise "Unknown parameter [#{param_key}]"
          end
          if params[:type]
            type_value = params[:type]
            if ['array', Array].include? type_value
              params[:type] = 'array'
            else
              raise "Unknown type [#{type_value}]"
            end
          end
        end
        current_response[:params] = params
      end

      current_endpoint[:responses][code] = current_response
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

    def validate_params(values, known_fields, field_name, general_values)
      result = {}
      values.each_pair do |key, value|
        key_sym = key.to_sym
        if known_fields.key? key_sym
          known_value = known_fields[key_sym]
          if known_value == String
            if value.is_a? String
              result[key_sym] = value
            else
              $stderr.puts "Swagger: property [#{key}] value [#{value}] should be a String for #{field_name}: #{general_values}"
            end
          else
            if value.is_a? Hash
              sub_params = validate_params(value, known_value, field_name, general_values)
              if sub_params
                result[key_sym] = sub_params
              end
            else
              $stderr.puts "Swagger: property [#{key}] value [#{value}] should be a Hash for #{field_name}: #{general_values}"
            end
          end
        else
          if logging?
            $stderr.puts "Swagger: unknown property [#{key}] for #{field_name}: #{general_values}"
          end
        end
      end
      result.empty? ? nil : result
    end

  end

end
