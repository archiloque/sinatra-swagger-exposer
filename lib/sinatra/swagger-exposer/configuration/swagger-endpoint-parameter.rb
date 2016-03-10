require_relative '../swagger-invalid-exception'

require_relative 'swagger-parameter-validation-helper'
require_relative 'swagger-type-property'
require_relative 'swagger-configuration-utilities'

module Sinatra

  module SwaggerExposer

    module Configuration

      class SwaggerEndpointParameter

        include SwaggerConfigurationUtilities
        include SwaggerParameterValidationHelper

        attr_reader :type, :name, :required, :default, :params, :items, :how_to_pass

        # Create a new instance
        # @param name [String] the name
        # @param description [String] the description
        # @param how_to_pass [String] how to pass the parameter
        # @param required [TrueClass] if the parameter is required
        # @param type [String] the type name
        # @param params [Hash] parameters
        # @param known_types [Array<String>] known custom types names
        def initialize(name, description, how_to_pass, required, type, params, known_types)
          check_name(name)
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
            get_type(type, PRIMITIVE_TYPES + known_types + [TYPE_FILE])
          else
            get_type(type, PRIMITIVE_TYPES_FOR_NON_BODY)
          end

          unless [true, false].include? required
            raise SwaggerInvalidException.new("Required should be a boolean instead of [#{required}]")
          end
          @required = required

          params = white_list_params(params, PARAMS_LIST, SwaggerTypeProperty::PROPERTIES)
          validate_params(@type == TYPE_ARRAY ? @items : @type, params)
          @default = params[PARAMS_DEFAULT]
          @params = params
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
            if @type == TYPE_ARRAY
              result[:type] = TYPE_ARRAY
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

      end
    end
  end
end
