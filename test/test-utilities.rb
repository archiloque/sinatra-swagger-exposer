module TestUtilities

  def must_raise_swag_and_equal(expression, value)
    expression.must_raise(Sinatra::SwaggerExposer::SwaggerInvalidException).message.must_equal(value)
  end

  def new_info(content)
    require_relative '../lib/sinatra/swagger-exposer/configuration/swagger-info'
    Sinatra::SwaggerExposer::Configuration::SwaggerInfo.new(content)
  end

  def new_er(type, description, known_types = [], headers = [], known_headers = nil)
    require_relative '../lib/sinatra/swagger-exposer/configuration/swagger-endpoint-response'
    unless known_headers
      require_relative '../lib/sinatra/swagger-exposer/configuration/swagger-response-headers'
      known_headers = Sinatra::SwaggerExposer::Configuration::SwaggerResponseHeaders.new
    end
    Sinatra::SwaggerExposer::Configuration::SwaggerEndpointResponse.new(type, description, known_types, headers, known_headers)
  end

  def new_t(type_name, type_properties, known_types = [])
    require_relative '../lib/sinatra/swagger-exposer/configuration/swagger-type'
    Sinatra::SwaggerExposer::Configuration::SwaggerType.new(type_name, type_properties, known_types)
  end

  def new_e(type, sinatra_path, parameters = [], responses = {}, summary = nil, description = nil, tags = nil, explicit_path = nil, produces = nil, operation_id=nil)
    require_relative '../lib/sinatra/swagger-exposer/configuration/swagger-endpoint'
    Sinatra::SwaggerExposer::Configuration::SwaggerEndpoint.new(type, sinatra_path, parameters, responses, summary, description, tags, explicit_path, produces, operation_id)
  end

  def new_ep(name, description, how_to_pass, required, type, params = {}, known_types = [])
    Sinatra::SwaggerExposer::Configuration::SwaggerEndpointParameter.new(name, description, how_to_pass, required, type, params, known_types)
  end

end
