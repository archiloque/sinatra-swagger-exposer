require_relative '../swagger-parameter-helper'

module Sinatra

  module SwaggerExposer

    module Configuration

      # Helper for validating parameters
      module SwaggerParameterValidationHelper

        include Sinatra::SwaggerExposer::SwaggerParameterHelper

        # Validate parameters
        # @param type [String] the parameter type
        # @param params [Hash]
        def validate_params(type, params)
          validate_limit_parameters(type, params)
          validate_length_parameters(type, params)
        end

        # Test if a parameter is a boolean
        # @param name the parameter's name
        # @param value value the parameter's value
        # @return [NilClass]
        def check_boolean(name, value)
          unless [true, false].include? value
            raise SwaggerInvalidException.new("Invalid boolean value [#{value}] for [#{name}]")
          end
        end

        # Validate the limit parameters
        # @param type [String] the parameter type
        # @param params [Hash] the parameters
        def validate_limit_parameters(type, params)
          max = validate_limit_parameter(type, params, PARAMS_MAXIMUM, PARAMS_EXCLUSIVE_MAXIMUM)
          min = validate_limit_parameter(type, params, PARAMS_MINIMUM, PARAMS_EXCLUSIVE_MINIMUM)
          if min && max && (max < min)
            raise SwaggerInvalidException.new("Minimum value [#{min}] can't be more than maximum value [#{max}]")
          end
        end

        # Validate a limit param like maximum and exclusiveMaximum
        # @param type [String] the parameter type
        # @param params [Hash] the parameters
        # @param limit_param_name [Symbol] the limit parameter name
        # @param exclusive_limit_param_name [Symbol] the exclusive limit parameter name
        def validate_limit_parameter(type, params, limit_param_name, exclusive_limit_param_name)
          parameter_value = nil
          if params.key? limit_param_name
            unless [TYPE_INTEGER, TYPE_NUMBER].include? @type
              raise SwaggerInvalidException.new("Parameter #{limit_param_name} can only be specified for types #{TYPE_INTEGER} or #{TYPE_NUMBER} and not for [#{@type}]")
            end
            parameter_value = params[limit_param_name]
            unless parameter_value.is_a? Numeric
              raise SwaggerInvalidException.new("Parameter #{limit_param_name} must be a numeric and can not be [#{parameter_value}]")
            end
          end

          if params.key? exclusive_limit_param_name
            check_boolean(exclusive_limit_param_name, params[exclusive_limit_param_name])
            unless params.key? limit_param_name
              raise SwaggerInvalidException.new("You can't have a #{exclusive_limit_param_name} value without a #{limit_param_name}")
            end
          end
          parameter_value
        end

        # Validate the length parameters minLength and maxLength
        # @param type [String] the parameter type
        # @param params [Hash] the parameters
        def validate_length_parameters(type, params)
          min_length = validate_length_parameter(type, params, PARAMS_MIN_LENGTH)
          max_length = validate_length_parameter(type, params, PARAMS_MAX_LENGTH)

          if min_length && max_length && (max_length < min_length)
            raise SwaggerInvalidException.new("Minimum length #{min_length} can't be more than maximum length #{max_length}")
          end
        end

        # Validate a length param like minLength and maxLength
        # @param type [String] the parameter type
        # @param params [Hash] the parameters
        # @param length_param_name [Symbol] the length parameter name
        # @return [Integer] the parameter value if it is present
        def validate_length_parameter(type, params, length_param_name)
          if params.key? length_param_name
            if type == TYPE_STRING
              parameter_value = params[length_param_name]
              unless parameter_value.is_a? Integer
                raise SwaggerInvalidException.new("Parameter #{length_param_name} must be an integer and can not be [#{parameter_value}]")
              end
              parameter_value
            else
              raise SwaggerInvalidException.new("Parameter #{length_param_name} can only be specified for type #{TYPE_STRING} and not for [#{@type}]")
            end

          else
            nil
          end
        end

      end
    end
  end
end
