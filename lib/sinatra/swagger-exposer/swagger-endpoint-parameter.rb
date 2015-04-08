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
          raise SwaggerInvalidException.new("Unknown how to pass value [#{how_to_pass}], registered types are #{HOW_TO_PASS.join(', ')}")
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

        if params
          white_list_params(params, [:format, :default, :example])
        end
        @params = params
      end

      def preprocessor
        SwaggerParameterPreprocessor.new(@name, @how_to_pass, @required, @type, @params[:default])
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
                result[:schema] = {'$ref' => "#/definitions/#{@items}"}
              end
            end
          else
            if PRIMITIVE_TYPES.include? @type
              result[:type] = @type
            else
              result[:schema] = {'$ref' => "#/definitions/#{@type}"}
            end
          end
        end

        if @description
          result[:description] = @description
        end
        if @params
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
            :params => @params,
            :description => @description,
        }.to_json
      end

    end

  end
end
