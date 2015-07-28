require_relative 'swagger-type'
require_relative '../swagger-utilities'
require_relative '../swagger-invalid-exception'

module Sinatra

  module SwaggerExposer

    module Configuration

      # Contain all the declared types
      class SwaggerTypes

        attr_reader :types

        include Sinatra::SwaggerExposer::SwaggerUtilities

        def initialize
          @types = {}
        end

        def [](name)
          @types[name]
        end

        # Add a new swagger type
        # @param name [String] the type name
        # @param params [Hash] the type params
        def add_type(name, params)
          if @types.key? name
            raise SwaggerInvalidException.new("Type [#{name}] already exist with value #{@types[name]}")
          end
          @types[name] = SwaggerType.new(name, params, @types.keys)
        end

        def types_names
          @types.keys
        end

        def to_swagger
          if @types.empty?
            nil
          else
            hash_to_swagger(@types)
          end
        end

      end
    end
  end
end
