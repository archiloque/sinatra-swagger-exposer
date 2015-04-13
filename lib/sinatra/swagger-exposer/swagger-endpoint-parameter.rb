require_relative 'swagger-invalid-exception'
require_relative 'swagger-parameter-preprocessor'
require_relative 'swagger-utilities'

module Sinatra

  module SwaggerExposer

    class SwaggerEndpointParameter

      include SwaggerUtilities

      HOW_TO_PASS_BODY = 'body'
      HOW_TO_PASS_HEADER = 'header'
      HOW_TO_PASS_PATH = 'path'
      HOW_TO_PASS_QUERY = 'query'
      HOW_TO_PASS = [HOW_TO_PASS_PATH, HOW_TO_PASS_QUERY, HOW_TO_PASS_HEADER, 'formData', HOW_TO_PASS_BODY]

      TYPE_INTEGER = 'integer'
      TYPE_BOOLEAN = 'boolean'
      TYPE_NUMBER = 'number'
      TYPE_STRING = 'string'
      PRIMITIVE_TYPES_FOR_NON_BODY = [TYPE_STRING, TYPE_NUMBER, TYPE_INTEGER, TYPE_BOOLEAN]

      PARAMS_FORMAT = :format
      PARAMS_DEFAULT = :default
      PARAMS_EXAMPLE = :example
      PARAMS_MAXIMUM = :maximum
      PARAMS_MINIMUM = :minimum
      PARAMS_EXCLUSIVE_MINIMUM = :exclusiveMinimum
      PARAMS_EXCLUSIVE_MAXIMUM = :exclusiveMaximum
      PARAMS_LIST = [
          PARAMS_FORMAT,
          PARAMS_DEFAULT,
          PARAMS_EXAMPLE,
          PARAMS_MAXIMUM,
          PARAMS_MINIMUM,
          PARAMS_EXCLUSIVE_MINIMUM,
          PARAMS_EXCLUSIVE_MAXIMUM,
      ]

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
        validate_limit_parameter(params, PARAMS_MAXIMUM, PARAMS_EXCLUSIVE_MAXIMUM)
        validate_limit_parameter(params, PARAMS_MINIMUM, PARAMS_EXCLUSIVE_MINIMUM)
      end

      def preprocessor
        SwaggerParameterPreprocessor.new(@name, @how_to_pass, @required, @type, @params[:default], @params)
      end

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

      # Validate a limit param like maximum and exclusiveMaximum
      # @param params [Hash] the parameters
      # @param limit_param_name [Symbol] the limit parameter name
      # @param exclusive_limit_param_name [Symbol] the exclusive limit parameter name
      def validate_limit_parameter(params, limit_param_name, exclusive_limit_param_name)
        if params.key? limit_param_name
          unless [TYPE_INTEGER, TYPE_NUMBER].include? @type
            raise SwaggerInvalidException.new("Parameter #{limit_param_name} can only be specified for type #{TYPE_INTEGER} and #{TYPE_NUMBER} and not for [#{@type}]")
          end
        end

        if params.key? exclusive_limit_param_name
          check_boolean(PARAMS_EXCLUSIVE_MINIMUM, params[exclusive_limit_param_name])
          unless params.key? limit_param_name
            raise SwaggerInvalidException.new("You can't have a #{exclusive_limit_param_name} value without a #{limit_param_name}")
          end
        end
      end

    end

  end
end
