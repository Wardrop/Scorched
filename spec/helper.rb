require 'rack/test'
require_relative '../lib/scorched.rb'

# RSpec.
RSpec.configure do |c|
  c.alias_example_to :they
  # c.backtrace_clean_patterns = []
end

module Scorched
  class TestApp < Controller; end
  class ChildController < TestApp; end
end

def app
  Scorched::TestApp
end

# To save ourselves from namespace pollution by using `include Rack::Test::Methods`, we use a constant for accessing
# methods provided by Rack::Test.
Scorched::RT = Class.new{ include Rack::Test::Methods }.new
