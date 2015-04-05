require_relative 'swagger-invalid-exception'
require_relative 'swagger-utilities'

module Sinatra

  module SwaggerExposer

    class SwaggerEndpointParameter

      include SwaggerUtilities

      HOW_TO_PASS_BODY = 'body'
      HOW_TO_PASS= ['path', 'query', 'header', 'formData'] + [HOW_TO_PASS_BODY]
      PRIMITIVE_TYPES_FOR_NON_BODY = ['string', 'number', 'integer', 'boolean']

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
          white_list_params(params, [:format])
        end
        @params = params

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
