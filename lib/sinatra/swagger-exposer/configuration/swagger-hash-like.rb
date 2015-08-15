require_relative '../swagger-invalid-exception'

require_relative 'swagger-configuration-utilities'

module Sinatra

  module SwaggerExposer

    module Configuration

      # A hash-like for groups of things
      class SwaggerHashLike

        include SwaggerConfigurationUtilities

        def initialize(things)
          @things = things
        end

        def [](name)
          @things[name]
        end

        def key?(name)
          @things.key? name
        end

        def check_duplicate(name, type_name)
          if key?(name)
            raise SwaggerInvalidException.new("#{type_name} [#{name}] already exist with value #{@things[name]}")
          end
        end

        def to_swagger
          if @things.empty?
            nil
          else
            hash_to_swagger(@things)
          end
        end

      end
    end
  end
end
