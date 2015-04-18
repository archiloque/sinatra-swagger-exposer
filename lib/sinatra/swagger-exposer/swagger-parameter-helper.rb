module Sinatra

  module SwaggerExposer

    # Helper for handling the parameters
    module SwaggerParameterHelper

      HOW_TO_PASS_BODY = 'body'
      HOW_TO_PASS_HEADER = 'header'
      HOW_TO_PASS_PATH = 'path'
      HOW_TO_PASS_QUERY = 'query'
      HOW_TO_PASS = [HOW_TO_PASS_PATH, HOW_TO_PASS_QUERY, HOW_TO_PASS_HEADER, 'formData', HOW_TO_PASS_BODY]

      TYPE_BOOLEAN = 'boolean'
      TYPE_BYTE = 'byte'
      TYPE_DATE = 'date'
      TYPE_DOUBLE = 'double'
      TYPE_DATE_TIME = 'dateTime'
      TYPE_FLOAT = 'float'
      TYPE_INTEGER = 'integer'
      TYPE_LONG = 'long'
      TYPE_NUMBER = 'number'
      TYPE_PASSWORD = 'password'
      TYPE_STRING = 'string'

      PRIMITIVE_TYPES = [
          TYPE_INTEGER,
          TYPE_LONG,
          TYPE_FLOAT,
          TYPE_DOUBLE,
          TYPE_STRING,
          TYPE_BYTE,
          TYPE_BOOLEAN,
          TYPE_DATE,
          TYPE_DATE_TIME,
          TYPE_PASSWORD,
      ]

      PRIMITIVE_TYPES_FOR_NON_BODY = [TYPE_STRING, TYPE_NUMBER, TYPE_INTEGER, TYPE_BOOLEAN]

      PARAMS_FORMAT = :format
      PARAMS_DEFAULT = :default
      PARAMS_EXAMPLE = :example

      # For numbers
      PARAMS_MINIMUM = :minimum
      PARAMS_MAXIMUM = :maximum
      PARAMS_EXCLUSIVE_MINIMUM = :exclusiveMinimum
      PARAMS_EXCLUSIVE_MAXIMUM = :exclusiveMaximum

      # For strings
      PARAMS_MIN_LENGTH = :minLength
      PARAMS_MAX_LENGTH = :maxLength

      PARAMS_LIST = [
          PARAMS_FORMAT,
          PARAMS_DEFAULT,
          PARAMS_EXAMPLE,
          PARAMS_MINIMUM,
          PARAMS_MAXIMUM,
          PARAMS_EXCLUSIVE_MINIMUM,
          PARAMS_EXCLUSIVE_MAXIMUM,
          PARAMS_MIN_LENGTH,
          PARAMS_MAX_LENGTH,
      ]


    end

  end
end
