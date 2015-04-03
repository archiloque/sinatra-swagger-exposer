module Sinatra

  module SwaggerExposer

    # Create the swagger content
    class SwaggerContentCreator

      def initialize(app)
        @app = app
      end

      def log(message)
        if @app.logging?
          $stderr.puts message
        end
      end

      def create_content(types, endpoints, info)
        result_endpoints = create_endpoints(endpoints)

        result_types = {}
        types.each_pair do |name, value|
          result_types[name] = create_type(value)
        end

        result = {
            swagger: '2.0',
            consumes: ['application/json'],
            produces: ['application/json'],
            paths: result_endpoints,
            definitions: result_types,
        }

        # Info is already processed
        if info
          result[:info] = info
        end

        result
      end

      def create_endpoints(endpoints)
        result_endpoints = {}

        # swagger need the endpoints to be grouped by path
        endpoints_by_path = endpoints.group_by { |endpoint| endpoint[:path] }
        endpoints_by_path.keys.sort.each do |path|
          endpoints = endpoints_by_path[path]

          result_endpoints_for_path = {}
          endpoints.each do |endpoint|
            result_endpoint = create_endpoint(endpoint)
            result_endpoints_for_path[endpoint[:type]] = result_endpoint
          end

          result_endpoints[path] = result_endpoints_for_path
        end
        result_endpoints
      end

      TYPE_ATTRIBUTES = [:required, :example, :properties]

      def create_type(type_params)
        result_type = {}

        if type_params.key? :properties
          result_properties = {}
          type_params[:properties].each_pair do |property_name, property_info|
            result_property = create_type_property(property_name, property_info)
            if result_property
              result_properties[property_name] = result_property
            end
          end
          unless result_properties.empty?
            result_type[:properties] = result_properties
          end
        end

        (TYPE_ATTRIBUTES - [:properties]).each do |property_key|
          if type_params.key? property_key
            result_type[property_key] = type_params[property_key]
          end
        end

        type_params.each_pair do |property_name, property_value|
          unless TYPE_ATTRIBUTES.include? property_name
            log "Swagger: unknown property [#{property_name}] for [#{property_name}]: #{type_params}"
          end
        end

      end

      TYPE_PROPERTIES_ATTRIBUTES = [:type, :format, :example, :description, :items]

      def create_type_property(property_name, property_info)
        result = {}

        TYPE_PROPERTIES_ATTRIBUTES.each do |known_attribute|
          if property_info.key? known_attribute
            result[known_attribute] = create_property_attribute(known_attribute, property_info, property_name)
          end
        end

        if result[:items] && (result[:type] != 'array')
          log "Swagger: specifying an items property [#{result[:items]}] for a non array type [#{result[:type]}] for [#{property_name}]: #{property_info}"
        end

        property_info.each_pair do |property_name, property_value|
          unless TYPE_PROPERTIES_ATTRIBUTES.include? property_name
            log "Swagger: unknown property [#{property_name}] for [#{property_name}]: #{property_info}"
          end
        end

        result.empty? ? nil : result
      end

      def create_property_attribute(attribute_name, property_info, property_name)
        attribute_value = property_info[attribute_name]
        if attribute_value.is_a? Class
          attribute_value = attribute_value.to_s.downcase
        elsif attribute_value.is_a? Hash
          if attribute_name != :items
            log "Swagger: property is a hash [#{attribute_value}] for a type that shouldn't be [#{attribute_name}] for [#{property_name}]: #{property_info}"
          end
          attribute_value.each_pair do |key, value|
            if value.is_a? Class
              attribute_value[key] = value.to_s.downcase
            end
          end
        end
        attribute_value
      end

      def create_endpoint(endpoint_params)
        result_endpoint = {
            produces: ['application/json']
        }
        [:summary, :description].each do |property_name|
          if endpoint_params[property_name]
            result_endpoint[property_name] = endpoint_params[property_name]
          end
        end
        responses = endpoint_params[:responses]
        if responses && (!responses.empty?)
          result_responses = {}
          responses.each_pair do |code, content|
            result_responses[code] = create_endpoint_response(content)
          end
          result_endpoint[:responses] = result_responses
        end
        result_endpoint
      end


      def create_endpoint_response(reponse_params)
        result_response = {
            :description => reponse_params[:description],
        }
        if reponse_params[:params] && reponse_params[:params][:type]
          result_response[:schema] = {
              :type => reponse_params[:params][:type],
              :items => {
                  '$ref' => "#/definitions/#{reponse_params[:type]}",
              }
          }
        else
          result_response[:schema] = {
              '$ref' => "#/definitions/#{reponse_params[:type]}",
          }
        end
        result_response
      end

    end

  end

end
