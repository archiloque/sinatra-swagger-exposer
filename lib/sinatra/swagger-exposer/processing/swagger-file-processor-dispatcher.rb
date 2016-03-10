require_relative '../swagger-parameter-helper'

module Sinatra

  module SwaggerExposer

    module Processing

      # Fake dispatcher for files
      class SwaggerFileProcessorDispatcher

        # Initialize
        # @param name [String] the name
        # @param required [TrueClass] if the parameter is required
        def initialize(name, required)
          @name = name
          @required = required
        end

        def useful?
          @required
        end

        # Process the value
        def process(app, parsed_body)
          if app.params.key?(@name.to_s) && (!app.params[@name.to_s].nil?)
          elsif @required
            raise SwaggerInvalidException.new("Mandatory value [#{@name}] is missing")
          end
        end

      end
    end
  end
end