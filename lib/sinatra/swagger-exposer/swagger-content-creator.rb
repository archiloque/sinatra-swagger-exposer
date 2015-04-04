require_relative 'swagger-utilities'

module Sinatra

  module SwaggerExposer

    # Create the swagger content
    class SwaggerContentCreator

      include SwaggerUtilities

      def initialize(swagger_info, swagger_types, swagger_endpoints)
        @swagger_info = swagger_info
        @swagger_types = swagger_types
        @swagger_endpoints = swagger_endpoints
      end

      def to_swagger
        result = {
            swagger: '2.0',
            consumes: ['application/json'],
            produces: ['application/json'],
        }
        if @swagger_info
          result[:info] = @swagger_info.to_swagger
        end

        unless @swagger_types.empty?
          result[:definitions] = hash_to_swagger(@swagger_types)
        end

        unless @swagger_endpoints.empty?
          result_endpoints = {}

          # swagger need the endpoints to be grouped by path
          endpoints_by_path = @swagger_endpoints.group_by { |endpoint| endpoint.path }
          endpoints_by_path.keys.sort.each do |path|
            endpoints = endpoints_by_path[path]

            result_endpoints_for_path = {}
            endpoints.each do |endpoint|
              result_endpoints_for_path[endpoint.type] = endpoint.to_swagger
            end

            result_endpoints[path] = result_endpoints_for_path

          end
          result[:paths] = result_endpoints
        end

        result
      end

    end

  end

end
