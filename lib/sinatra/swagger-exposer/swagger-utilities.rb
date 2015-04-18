require_relative 'swagger-invalid-exception'
require_relative 'swagger-parameter-helper'

module Sinatra

  module SwaggerExposer

    module SwaggerUtilities

      include ::Sinatra::SwaggerExposer::SwaggerParameterHelper

      def ref_to_type(type)
        {'$ref' => "#/definitions/#{type}"}
      end

      def hash_to_swagger(hash)
        result = {}
        hash.each_pair do |key, value|
          result[key] = value.to_swagger
        end
        result
      end

      # Transform a type into a String
      # @return [String]
      def type_to_s(value)
        if [TrueClass, FalseClass].include? value
          TYPE_BOOLEAN
        elsif value == DateTime
          TYPE_DATE_TIME
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

      # Validate if a parameter is in a list of available values
      # @param params [Hash] the parameters
      # @param allowed_values [Enumerable, #include?] the allowed values
      # @param ignored_values [Enumerable, #include?] values to ignore
      # @return [Hash] the filtered hash
      def white_list_params(params, allowed_values, ignored_values = [])
        result = {}
        params.each_pair do |key, value|
          if allowed_values.include? key
            result[key] = value
          elsif !ignored_values.include?(key)
            raise SwaggerInvalidException.new("Unknown property [#{key}] with value [#{value}]#{list_or_none(allowed_values, 'properties')}")
          end
        end
        result
      end

      def list_or_none(list, name)
        if list.empty?
          ", no available #{name}"
        else
          ", possible #{name} are #{list.join(', ')}"
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

      # Validate if a type is in a list of available values
      # @param type [String] the parameter
      # @param allowed_values [Enumerable, #include?] the allowed values
      # @return [NilClass]
      def check_type(type, allowed_values)
        if allowed_values.empty?
          raise SwaggerInvalidException.new("Unknown type [#{type}], no available type")
        elsif !allowed_values.include?(type)
          raise SwaggerInvalidException.new("Unknown type [#{type}]#{list_or_none(allowed_values, 'types')}")
        end
      end

    end

  end

end

