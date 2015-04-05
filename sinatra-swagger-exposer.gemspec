# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sinatra/swagger-exposer/version'

Gem::Specification.new do |spec|
  spec.name          = 'sinatra-swagger-exposer'
  spec.version       = Sinatra::SwaggerExposer::VERSION
  spec.authors       = ['Julien Kirch']

  spec.summary       = %q{Expose swagger API from your Sinatra app}
  spec.description   = %q{This Sinatra extension enable you to add metadata to your code and to expose your API as a Swagger endpoint}
  spec.homepage      = 'https://github.com/archiloque/sinatra-swagger-exposer'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ['lib']

  spec.add_dependency 'sinatra', '~> 1.4'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.5'
  spec.add_development_dependency 'rack-test', '~> 0.6.3'
  spec.add_development_dependency 'simplecov'

end
