module Sinatra

  module SwaggerExposer

    module SwaggerUtilities

      def hash_to_swagger(hash)
        result = {}
        hash.each_pair do |key, value|
          result[key] = value.to_swagger
        end
        result
      end

    end

  end

end

