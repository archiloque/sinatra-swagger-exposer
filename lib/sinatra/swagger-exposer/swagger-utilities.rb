require_relative 'swagger-invalid-exception'

module Sinatra

  module SwaggerExposer

    module SwaggerUtilities

      PRIMITIVE_TYPES = [
          'integer',
          'long',
          'float',
          'double',
          'string',
          'byte',
          'boolean',
          'date',
          'dateTime',
          'password'
      ]

      def hash_to_swagger(hash)
        result = {}
        hash.each_pair do |key, value|
          result[key] = value.to_swagger
        end
        result
      end

      def type_to_s(value)
        if [TrueClass, FalseClass].include? value
          'boolean'
        elsif value.is_a? Class
          value.to_s.downcase
        else
          value
        end
      end

      def get_type(type, possible_values)
        @type = type
        if type.nil?
          raise SwaggerInvalidException.new('Type is nil')
        elsif type.is_a?(String) || @type.is_a?(Class)
          @type = type_to_s(@type)
          check_type(@type, possible_values)
        elsif @type.is_a? Array
          @items = type_to_s(get_array_type(@type))
          check_type(@items, possible_values)
          @type = 'array'
        else
          raise SwaggerInvalidException.new("Type [#{@type}] of has an unknown type, should be a class, a string or an array")
        end
      end

      def white_list_params(params, allowed_params)
        params.each_pair do |key, value|
          unless allowed_params.include? key
            raise SwaggerInvalidException.new("Unknown property [#{key}] for with value [#{value}], known properties are #{allowed_params.join(', ')}")
          end
        end
      end

      private

      def get_array_type(array)
        if array.empty?
          raise SwaggerInvalidException.new('Type is an empty array, you should specify a type as the array content')
        elsif array.length > 1
          raise SwaggerInvalidException.new("Type [#{array}] has more than one entry, it should only have one")
        else
          type_to_s(array[0])
        end
      end

      def check_type(type, possible_values)
        unless possible_values.include? type
          raise SwaggerInvalidException.new("Unknown type [#{type}], possible types are #{possible_values.join(', ')}")
        end
      end

    end

  end

end

