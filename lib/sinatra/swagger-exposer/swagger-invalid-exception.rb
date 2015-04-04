module Sinatra

  module SwaggerExposer

    # When something is wrong
    class SwaggerInvalidException < Exception

      def initialize(message)
        super(message)
      end

    end

  end

end
