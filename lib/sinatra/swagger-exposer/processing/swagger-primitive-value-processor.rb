require 'date'

require_relative 'swagger-base-value-processor'
require_relative '../swagger-parameter-helper'
require_relative '../swagger-invalid-exception'

module Sinatra

  module SwaggerExposer

    module Processing

      # Validate primitive value
      class SwaggerPrimitiveValueProcessor < SwaggerBaseValueProcessor

        include Sinatra::SwaggerExposer::SwaggerParameterHelper

        attr_reader :type, :params

        # Initialize
        # @param name [String] the name
        # @param required [TrueClass] if the parameter is required
        # @param type [String] the type name
        # @param default [Object] the default value
        # @param params [Hash] parameters
        def initialize(name, required, type, default, params)
          super(name, required, default)
          @type = type
          @params = params
        end

        def useful?
          super ||
            [TYPE_NUMBER, TYPE_INTEGER, TYPE_BOOLEAN, TYPE_DATE_TIME].include?(@type) || # Must check type
            (@params.key? PARAMS_MIN_LENGTH) || (@params.key? PARAMS_MAX_LENGTH) # Must check string
        end

        # Dispatch method
        def validate_value(value)
          case @type
            when TYPE_NUMBER
              return validate_value_number(value)
            when TYPE_INTEGER
              return validate_value_integer(value)
            when TYPE_BOOLEAN
              return validate_value_boolean(value)
            when TYPE_DATE_TIME
              return validate_value_date_time(value)
            else
              return validate_value_string(value)
          end
        end

        # Validate a boolean
        def validate_value_boolean(value)
          if (value == 'true') || value.is_a?(TrueClass)
            true
          elsif (value == 'false') || value.is_a?(FalseClass)
            false
          else
            raise SwaggerInvalidException.new("Value [#{name}] should be an boolean but is [#{value}]")
          end
        end

        # Validate an integer
        def validate_value_integer(value)
          begin
            i = Integer(value)
            if  i != value && value.is_a?(Float)
              raise SwaggerInvalidException.new("Value [#{name}] should be an integer but is [#{value}]")
            end
            value = i
            validate_numerical_value(value)
            value
          rescue ArgumentError
            raise SwaggerInvalidException.new("Value [#{name}] should be an integer but is [#{value}]")
          rescue TypeError
            raise SwaggerInvalidException.new("Value [#{name}] should be an integer but is [#{value}]")
          end
        end

        # Validate a number value
        def validate_value_number(value)
          begin
            value = Float(value)
            validate_numerical_value(value)
            return value
          rescue ArgumentError
            raise SwaggerInvalidException.new("Value [#{name}] should be a float but is [#{value}]")
          rescue TypeError
            raise SwaggerInvalidException.new("Value [#{name}] should be a float but is [#{value}]")
          end
        end

        # Validate a numerical value
        # @param value [Numeric] the value
        def validate_numerical_value(value)
          validate_numerical_value_internal(
            value,
            PARAMS_MINIMUM,
            PARAMS_EXCLUSIVE_MINIMUM,
            '>=',
            '>')
          validate_numerical_value_internal(
            value,
            PARAMS_MAXIMUM,
            PARAMS_EXCLUSIVE_MAXIMUM,
            '<=',
            '<')
        end

        # Validate a date time
        def validate_value_date_time(value)
          begin
            DateTime.rfc3339(value)
          rescue ArgumentError
            raise SwaggerInvalidException.new("Value [#{name}] should be a date time but is [#{value}]")
          end
        end

        # Validate a string
        def validate_value_string(value)
          if value
            validate_value_string_length(value, PARAMS_MIN_LENGTH, '>=')
            validate_value_string_length(value, PARAMS_MAX_LENGTH, '<=')
          end
          value
        end

        # Validate the length of a string
        # @param value the value to check
        # @param limit_param_name [Symbol] the param that contain the value to compare to
        # @param limit_param_method [String] the comparison method to call
        def validate_value_string_length(value, limit_param_name, limit_param_method)
          if @params.key? limit_param_name
            target_value = @params[limit_param_name]
            unless value.length.send(limit_param_method, target_value)
              raise SwaggerInvalidException.new("Value [#{name}] length should be #{limit_param_method} than #{target_value} but is #{value.length} for [#{value}]")
            end
          end
        end

        # Validate the value of a number
        # @param value the value to check
        # @param limit_param_name [Symbol] the param that contain the value to compare to
        # @param exclusive_limit_param_name [Symbol] the param that indicates if the comparison is absolute
        # @param limit_param_method [String] the comparison method to call
        # @param exclusive_limit_param_method [String] the absolute comparison method to call
        def validate_numerical_value_internal(value, limit_param_name, exclusive_limit_param_name, limit_param_method, exclusive_limit_param_method)
          if @params.key? limit_param_name
            target_value = @params[limit_param_name]
            method_to_call = @params[exclusive_limit_param_name] ? exclusive_limit_param_method : limit_param_method
            unless value.send(method_to_call, target_value)
              raise SwaggerInvalidException.new("Value [#{name}] should be #{method_to_call} than [#{target_value}] but is [#{value}]")
            end
          end
        end

      end
    end
  end
end