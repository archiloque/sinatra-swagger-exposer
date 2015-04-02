require 'sinatra/base'
require 'json'

module Sinatra

  # Expose swagger API from your Sinatra app
  module SwaggerExposer

    def self.registered(app)
      app.set :swagger_endpoints, []
      app.set :swagger_current_endpoint, {}

      app.get '/swagger_doc.json' do
        endpoints_by_path = settings.swagger_endpoints.group_by { |e| e[:path] }
        result_endpoints = {}

        endpoints_by_path.each_pair do |path, endpoints|
          result_endpoints_for_path = {}
          endpoints.each do |endpoint|
            result_endpoint = {}
            if endpoint[:description]
              result_endpoint[:description] = endpoint[:description]
            end
            result_endpoints_for_path[endpoint[:type]] = result_endpoint
          end
          result_endpoints[path] = result_endpoints_for_path
        end
        content_type :json
        {
            swagger: '2.0',
            consumes: [
                'application/json'
            ],
            produces: [
                'application/json'
            ],
            paths: result_endpoints,
            definitions: {},
        }.to_json
      end
    end

    private

    def process_endpoint(type, args)
      current_endpoint = settings.swagger_current_endpoint
      current_endpoint[:type] = type
      current_endpoint[:path] = args[0]
      if logging?
        $stderr.puts "Swagger: found new endpoint #{current_endpoint}"
      end
      settings.swagger_endpoints << current_endpoint
      set :swagger_current_endpoint, {}
    end

    public

    def description(text)
      settings.swagger_current_endpoint[:description] = text
    end

    def delete(*args, &block)
      process_endpoint('delete', args)
      super(*args, &block)
    end

    def get(*args, &block)
      process_endpoint('get', args)
      super(*args, &block)
    end

    def head(*args, &block)
      process_endpoint('head', args)
      super(*args, &block)
    end

    def link(*args, &block)
      process_endpoint('link', args)
      super(*args, &block)
    end

    def options(*args, &block)
      process_endpoint('options', args)
      super(*args, &block)
    end

    def patch(*args, &block)
      process_endpoint('patch', args)
      super(*args, &block)
    end

    def post(*args, &block)
      process_endpoint('post', args)
      super(*args, &block)
    end

    def put(*args, &block)
      process_endpoint('put', args)
      super(*args, &block)
    end

    def unlink(*args, &block)
      process_endpoint('unlink', args)
      super(*args, &block)
    end

  end

end
