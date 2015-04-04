module TestUtilities

  def must_raise_swag_and_match(expression, value)
    expression.must_raise(Sinatra::SwaggerExposer::SwaggerInvalidException).message.must_match(value)
  end

end
