module Sinatra

  module SwaggerExposer

    # Process a response declaration
    class SwaggerResponseValidator
      def initialize(app)
        @app = app
      end

      def log(message)
        if @app.logging?
          $stderr.puts message
        end
      end

      def validate(current_endpoint, known_types, code, description, type, params)
        unless current_endpoint.key? :responses
          current_endpoint[:responses] = {}
        end
        if current_endpoint[:responses].key? code
          raise "Response [#{code}] already exist with value #{current_endpoint[:responses][code]}"
        end
        if type.is_a?(String) && (!known_types.key?(type))
          raise "Unknown type [#{type}], registered types are #{known_types.keys.join(', ')}"
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
        current_endpoint[code] = current_response
      end

    end

  end
end
