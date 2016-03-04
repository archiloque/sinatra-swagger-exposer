# Sinatra::SwaggerExposer

[![Code Climate](https://codeclimate.com/github/archiloque/sinatra-swagger-exposer/badges/gpa.svg)](https://codeclimate.com/github/archiloque/sinatra-swagger-exposer)
[![Build Status](https://travis-ci.org/archiloque/sinatra-swagger-exposer.svg?branch=master)](https://travis-ci.org/archiloque/sinatra-swagger-exposer)
[![Coverage Status](https://coveralls.io/repos/archiloque/sinatra-swagger-exposer/badge.svg?branch=master)](https://coveralls.io/r/archiloque/sinatra-swagger-exposer?branch=master)

Create Swagger endpoint for your Sinatra application.

This Sinatra extension enable you to add metadata to your code to

- expose your API as a [Swagger](http://swagger.io) endpoint.
- validate and enrich the invocation parameters
- validate the responses during test dans development

I'm adding features as I need them and it currently doesn't use all the Swagger options, so if you need one that is missing please open an issue.

## Design choices

- All the declarations are validated when the server is started
- The declarations are defined to look as ruby-ish as possible
- Declarations are used for parameters validation and enrichment

## Usage

To use it in your app :

```ruby
require 'sinatra/swagger-exposer/swagger-exposer'

class MyApp < Sinatra::Base

  register Sinatra::SwaggerExposer

  general_info(
      {
          version: '0.0.1',
          title: 'My app',
          description: 'My wonderful app',
          license: {
              name: 'MIT',
              url: 'http://opensource.org/licenses/MIT'
          }
      }
  )

  type 'Status',
               {
                   :properties => {
                       :status => {
                           :type => String,
                           :example => 'OK,
                       },
                   },
                   :required => [:status]
               }

  endpoint_description 'Base method to ping'
  endpoint_response 200, 'Status', 'Standard response'
  endpoint_tags 'Ping'
  get '/' do
    json({'status' => 'OK'})
  end

end
```

The swagger json endpoint will be exposed at `/swagger_doc.json`.

You can also use a more fluent variant by providing a hash to the `endpoint` method


```ruby
  endpoint :description => 'Base method to ping',
           :responses { 200 => ['Status', 'Standard response']}
           :tags 'Ping'
  get '/' do
    json({'status' => 'OK'})
  end
```

The hash should contains the key `description`, `summary`, `path`, `tags`, `responses` and `params`.
Note both `responses` and `params` takes a hash as argument `hash(param_name =>param_details)` and `hash(status_code=>res_param)`

If the equivalent methods have more than one param, theses are wrapped in an array.


## Detailed example

A more complete example is available [here](https://github.com/archiloque/sinatra-swagger-exposer/tree/master/example).

## About swagger-ui

- If you to use [swagger-ui](https://github.com/swagger-api/swagger-ui) with your app you will need to add croo-origin setup.
The easiest way is to use the [sinatra-cross_origin](https://github.com/britg/sinatra-cross_origin) gem. Fro a simple sample you can have a look at [example application](https://github.com/archiloque/sinatra-swagger-exposer/tree/master/example).
- Swagger-ui doesn't work with all the swagger features
  - Some of them like parameters maximum and minimum values are ignored
  - Some of them like extending types make the endpoint unusable

## Changes

Changelog is [here](https://github.com/archiloque/sinatra-swagger-exposer/blob/master/CHANGELOG.md).

## Resources

- [Swagger RESTful API Documentation Specification](https://github.com/swagger-api/swagger-spec/blob/master/versions/2.0.md).
- [Swagger json examples](https://github.com/swagger-api/swagger-spec/tree/master/examples/v2.0/json).
- [The swagger json schema](https://raw.githubusercontent.com/swagger-api/swagger-spec/master/schemas/v2.0/schema.json).

## Todo

- More parameters taken into account
- More validations where possible

## License

This software is released under the MIT license.
