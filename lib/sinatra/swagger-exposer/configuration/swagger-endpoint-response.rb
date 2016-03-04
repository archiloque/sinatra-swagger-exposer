require_relative '../swagger-invalid-exception'

require_relative 'swagger-configuration-utilities'

module Sinatra

  module SwaggerExposer

    module Configuration

      class SwaggerEndpointResponse

        include SwaggerConfigurationUtilities

        attr_reader :type, :items

        RESPONSE_PRIMITIVES_FILES = PRIMITIVE_TYPES + [TYPE_FILE]

        # @param type the type
        # @param description [String] the description
        # @param known_types [Array<String>] known custom types names
        # @param headers [Array<String] the headers names
        # @param known_headers [Sinatra::SwaggerExposer::Configuration::SwaggerResponseHeaders] the known headers
        def initialize(type, description, known_types, headers, known_headers)
          if type
            get_type(type, known_types + RESPONSE_PRIMITIVES_FILES)
          end

          if description
            @description = description
          end

          @headers = {}
          headers.each do |header_name|
            header_name = header_name.to_s
            if @headers.key? header_name
              raise SwaggerInvalidException.new("Duplicated header_name [#{header_name}]")
            end
            unless known_headers.key? header_name
              raise SwaggerInvalidException.new("Unknown header_name [#{header_name}]")
            end
            @headers[header_name] = known_headers[header_name]
          end

        end

        def to_swagger
          result = {}

          if @type
            if @type == TYPE_ARRAY
              schema = {:type => TYPE_ARRAY}
              if @items
                if RESPONSE_PRIMITIVES_FILES.include? @items
                  schema[:items] = {:type => @items}
                else
                  schema[:items] = ref_to_type(@items)
                end
              end
              result[:schema] = schema
            else
              if RESPONSE_PRIMITIVES_FILES.include? @type
                result[:schema] = {:type => @type}
              else
                result[:schema] = ref_to_type(@type)
              end
            end
          end

          if @description
            result[:description] = @description
          end

          unless @headers.empty?
            swagged_headers = {}
            @headers.each_pair do |name, value|
              swagged_headers[name] = value.to_swagger
            end
            result[:headers] = swagged_headers
          end

          result
        end

        def to_s
          {
            :type => @type,
            :items => @items,
            :description => @description,
          }.to_json
        end

      end
    end
  end
end
