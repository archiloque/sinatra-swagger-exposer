require_relative 'swagger-invalid-exception'

module Sinatra

  module SwaggerExposer

    # The info declaration
    class SwaggerInfo

      def initialize(values)
        @values = process(values, 'info', INFO_FIELDS, values)
      end

      # Known fields for the info field
      INFO_FIELDS = {
          :version => String,
          :title => String,
          :description => String,
          :termsOfService => String,
          :contact => {:name => String, :email => String, :url => String},
          :license => {:name  => String, :url => String},
      }

      # Recursive function
      # @param
      def process(current_hash, current_field_name, current_fields, top_level_hash)
        result = {}

        current_hash.each_pair do |current_key, current_value|
          key_sym = current_key.to_sym
          if current_fields.key? key_sym

            field_content = current_fields[key_sym]
            if field_content == String
              if current_value.is_a? String
                result[key_sym] = current_value
              else
                raise SwaggerInvalidException.new("Swagger: property [#{current_key}] value [#{current_value}] should be a String for #{current_field_name}: #{top_level_hash}")
              end
            else
              if current_value.is_a? Hash
                sub_params = process(current_value, current_field_name, field_content, top_level_hash)
                if sub_params
                  result[key_sym] = sub_params
                end
              else
                raise SwaggerInvalidException.new("Swagger: property [#{current_key}] value [#{current_value}] should be a Hash for #{current_field_name}: #{top_level_hash}")
              end
            end
          else
            raise SwaggerInvalidException.new("Swagger: unknown property [#{current_key}] for #{current_field_name}, possible keys are: #{current_fields.keys.join(', ')}: #{top_level_hash}")
          end
        end
        result.empty? ? nil : result
      end

      def to_swagger
        @values
      end

    end

  end
end
