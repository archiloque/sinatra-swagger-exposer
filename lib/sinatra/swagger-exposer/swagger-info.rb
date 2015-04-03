module Sinatra

  module SwaggerExposer

    # Process the info declaration
    class SwaggerInfoValidator
      def initialize(app)
        @app = app
      end

      def log(message)
        if @app.logging?
          $stderr.puts message
        end
      end

      # Known fields for the info field
      INFO_FIELDS = {
          :version => String,
          :title => String,
          :description => String,
          :termsOfService => String,
          :contact => {:name => String, :email => String, :url => String, },
          :license => {:name => String, :url => String, },
      }

      def validate(values, field_name, general_values, known_fields = INFO_FIELDS)
        result = {}
        values.each_pair do |key, value|
          key_sym = key.to_sym
          if known_fields.key? key_sym
            known_value = known_fields[key_sym]
            if known_value == String
              if value.is_a? String
                result[key_sym] = value
              else
                log "Swagger: property [#{key}] value [#{value}] should be a String for #{field_name}: #{general_values}"
              end
            else
              if value.is_a? Hash
                sub_params = validate(value, field_name, general_values, known_value)
                if sub_params
                  result[key_sym] = sub_params
                end
              else
                log "Swagger: property [#{key}] value [#{value}] should be a Hash for #{field_name}: #{general_values}"
              end
            end
          else
            log "Swagger: unknown property [#{key}] for #{field_name}: #{general_values}"
          end
        end
        result.empty? ? nil : result
      end

    end

  end
end
