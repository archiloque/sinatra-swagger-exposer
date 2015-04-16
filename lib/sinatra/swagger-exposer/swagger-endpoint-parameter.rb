require_relative 'swagger-invalid-exception'
require_relative 'swagger-parameter-helper'
require_relative 'swagger-parameter-preprocessor'
require_relative 'swagger-utilities'

module Sinatra

  module SwaggerExposer

    class SwaggerEndpointParameter

      include SwaggerUtilities
      include SwaggerParameterHelper

      def initialize(name, description, how_to_pass, required, type, params, known_types)
        unless name.is_a?(String) || name.is_a?(Symbol)
          raise SwaggerInvalidException.new("Name [#{name}] should be a string or a symbol")
        end
        name = name.to_s
        if name.empty?
          raise SwaggerInvalidException.new('Name should not be empty')
        end
        @name = name

        if description
          @description = description
        end

        how_to_pass = how_to_pass.to_s
        unless HOW_TO_PASS.include? how_to_pass
          raise SwaggerInvalidException.new("Unknown how to pass value [#{how_to_pass}]#{list_or_none(HOW_TO_PASS, 'registered types')}")
        end
        @how_to_pass = how_to_pass

        if @how_to_pass == HOW_TO_PASS_BODY
          get_type(type, PRIMITIVE_TYPES + known_types)
        else
          get_type(type, PRIMITIVE_TYPES_FOR_NON_BODY)
        end

        unless [true, false].include? required
          raise SwaggerInvalidException.new("Required should be a boolean instead of [#{required}]")
        end
        @required = required

        white_list_params(params, PARAMS_LIST)
        validate_params(params)
        @params = params
      end

      # Validate parameters
      # @param params [Hash]
      def validate_params(params)
        validate_limit_parameters(params)
        validate_length_parameters(params)
      end

      # Create the corresponding SwaggerParameterPreprocessor
      # @return [Sinatra::SwaggerExposer::SwaggerParameterPreprocessor]
      def preprocessor
        SwaggerParameterPreprocessor.new(@name, @how_to_pass, @required, @type, @params[:default], @params)
      end

      # Return the swagger version
      # @return [Hash]
      def to_swagger
        result = {
            :name => @name,
            :in => @how_to_pass,
            :required => @required
        }

        if @type
          if @type == 'array'
            result[:type] = 'array'
            if @items
              if PRIMITIVE_TYPES.include? @items
                result[:items] = {:type => @items}
              else
                result[:schema] = ref_to_type(@items)
              end
            end
          else
            if PRIMITIVE_TYPES.include? @type
              result[:type] = @type
            else
              result[:schema] = ref_to_type(@type)
            end
          end
        end

        if @description
          result[:description] = @description
        end
        unless @params.empty?
          result.merge!(@params)
        end

        result
      end

      def to_s
        {
            :name => @name,
            :in => @how_to_pass,
            :required => @required,
            :type => @type,
            :items => @items,
            :description => @description,
            :params => @params,
        }.to_json
      end

      private

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
      # @param params [Hash] the parameters
      def validate_limit_parameters(params)
        max = validate_limit_parameter(params, PARAMS_MAXIMUM, PARAMS_EXCLUSIVE_MAXIMUM)
        min = validate_limit_parameter(params, PARAMS_MINIMUM, PARAMS_EXCLUSIVE_MINIMUM)
        if min && max && (max < min)
          raise SwaggerInvalidException.new("Minimum value [#{min}] can't be more than maximum value [#{max}]")
        end
      end

      # Validate a limit param like maximum and exclusiveMaximum
      # @param params [Hash] the parameters
      # @param limit_param_name [Symbol] the limit parameter name
      # @param exclusive_limit_param_name [Symbol] the exclusive limit parameter name
      def validate_limit_parameter(params, limit_param_name, exclusive_limit_param_name)
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
      # @param params [Hash] the parameters
      def validate_length_parameters(params)
        min_length = validate_length_parameter(params, PARAMS_MIN_LENGTH)
        max_length = validate_length_parameter(params, PARAMS_MAX_LENGTH)

        if min_length && max_length && (max_length < min_length)
          raise SwaggerInvalidException.new("Minimum length #{min_length} can't be more than maximum length #{max_length}")
        end
      end

      # Validate a length param like minLength and maxLength
      # @param params [Hash] the parameters
      # @param length_param_name [Symbol] the length parameter name
      # @return [Integer] the parameter value if it is present
      def validate_length_parameter(params, length_param_name)
        if params.key? length_param_name
          if @type == TYPE_STRING
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
