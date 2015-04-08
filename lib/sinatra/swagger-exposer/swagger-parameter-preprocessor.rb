require_relative 'swagger-endpoint-parameter'
require_relative 'swagger-invalid-exception'

module Sinatra

  module SwaggerExposer

    # Process the parameters for validation and enrichment
    class SwaggerParameterPreprocessor

      def initialize(name, how_to_pass, required, type, default)
        @name = name.to_s
        @how_to_pass = how_to_pass
        @required = required
        @type = type
        @default = default

        # All headers are upcased
        if how_to_pass == SwaggerEndpointParameter::HOW_TO_PASS_HEADER
          @name.upcase!
        end
      end

      def useful?
        @required || (!@default.nil?) || [SwaggerEndpointParameter::TYPE_NUMBER, SwaggerEndpointParameter::TYPE_INTEGER, SwaggerEndpointParameter::TYPE_BOOLEAN].include?(@type)
      end

      def run(app, parsed_body)
        case @how_to_pass
          when SwaggerEndpointParameter::HOW_TO_PASS_QUERY, SwaggerEndpointParameter::HOW_TO_PASS_PATH
            check_param(app.params)
          when SwaggerEndpointParameter::HOW_TO_PASS_HEADER
            check_param(app.headers)
          when SwaggerEndpointParameter::HOW_TO_PASS_BODY
            check_param(parsed_body || {})
        end
      end

      def check_param(params)
        if params.key?(@name)
          params[@name] = validate_type(params[@name])
        elsif @required
          raise SwaggerInvalidException.new("Mandatory parameter [#{@name}] is missing")
        elsif @default
          params[@name] = @default
        end
        params
      end

      def validate_type(value)
        case @type
          when SwaggerEndpointParameter::TYPE_NUMBER
            return validate_type_number(value)
          when SwaggerEndpointParameter::TYPE_INTEGER
            return validate_type_integer(value)
          when SwaggerEndpointParameter::TYPE_BOOLEAN
            return validate_type_boolean(value)
        end
      end

      def validate_type_boolean(value)
        if (value == 'true') || value.is_a?(TrueClass)
          return true
        elsif (value == 'false') || value.is_a?(FalseClass)
          return false
        else
          raise SwaggerInvalidException.new("Parameter [#{@name}] should be an boolean but is [#{value}]")
        end
      end

      def validate_type_integer(value)
        begin
          f = Float(value)
          i = Integer(value)
          if f == i
            i
          else
            raise SwaggerInvalidException.new("Parameter [#{@name}] should be an integer but is [#{value}]")
          end
          return Integer(value)
        rescue ArgumentError
          raise SwaggerInvalidException.new("Parameter [#{@name}] should be an integer but is [#{value}]")
        rescue TypeError
          raise SwaggerInvalidException.new("Parameter [#{@name}] should be an integer but is [#{value}]")
        end
      end

      def validate_type_number(value)
        begin
          return Float(value)
        rescue ArgumentError
          raise SwaggerInvalidException.new("Parameter [#{@name}] should be a float but is [#{value}]")
        rescue TypeError
          raise SwaggerInvalidException.new("Parameter [#{@name}] should be a float but is [#{value}]")
        end
      end
    end

  end
end