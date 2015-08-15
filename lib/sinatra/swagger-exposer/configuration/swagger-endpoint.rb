require_relative '../swagger-invalid-exception'

require_relative 'swagger-configuration-utilities'

module Sinatra

  module SwaggerExposer

    module Configuration

      # An endpoint
      class SwaggerEndpoint

        include SwaggerConfigurationUtilities

        attr_reader :path, :type, :parameters

        def initialize(type, sinatra_path, parameters, responses, summary, description, tags, explicit_path, produces)
          @type = type
          @path = swagger_path(sinatra_path, explicit_path)

          @parameters = parameters
          @responses = responses

          @attributes = {}
          if summary
            @attributes[:summary] = summary
          end
          if description
            @attributes[:description] = description
          end
          if tags
            @attributes[:tags] = tags
          end
          if produces
            @attributes[:produces] = produces
          end
        end

        def to_swagger
          result = @attributes.clone

          unless @parameters.empty?
            result[:parameters] = @parameters.collect { |parameter| parameter.to_swagger }
          end

          unless @responses.empty?
            result[:responses] = hash_to_swagger(@responses)
          end

          result
        end

        REGEX_PATH_PARAM_MIDDLE = /\A(.*\/)\:([a-z]+)\/(.+)\z/
        REGEX_PATH_PARAM_END = /\A(.*)\/:([a-z]+)\z/

        # Get the endpoint swagger path
        # @param sinatra_path the path declared in the sinatra app
        # @param explicit_path an explicit path the user can specify
        def swagger_path(sinatra_path, explicit_path)
          if explicit_path
            explicit_path
          elsif sinatra_path.is_a? String
            while (m = REGEX_PATH_PARAM_MIDDLE.match(sinatra_path))
              sinatra_path = "#{m[1]}{#{m[2]}}/#{m[3]}"
            end
            if (m = REGEX_PATH_PARAM_END.match(sinatra_path))
              sinatra_path = "#{m[1]}/{#{m[2]}}"
            end
            sinatra_path
          else
            raise SwaggerInvalidException.new("You need to specify a path when using a non-string path [#{sinatra_path}]")
          end
        end

        def to_s
          {
              :type => @type,
              :path => @path,
              :attributes => @attributes,
              :parameters => @parameters,
              :responses => @responses,
          }.to_json
        end

      end
    end
  end
end
