require_relative 'swagger-hash-like'
require_relative 'swagger-type'

module Sinatra

  module SwaggerExposer

    module Configuration

      # Contain all the declared types
      class SwaggerTypes < SwaggerHashLike

        attr_reader :types

        def initialize
          @types = {}
          super(types)
        end

        # Add a new swagger type
        # @param name [String] the type name
        # @param params [Hash] the type params
        def add_type(name, params)
          check_duplicate(name, 'Type')
          @types[name] = SwaggerType.new(name, params, @types.keys)
        end

        def types_names
          @types.keys
        end

      end
    end
  end
end
