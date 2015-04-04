require 'simplecov'
SimpleCov.start do
  add_group 'lib', 'lib'
  add_filter 'test'
end

require 'minitest/autorun'
