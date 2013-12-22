ENV['RACK_ENV'] = 'production'

require 'rack/test'
require_relative '../lib/scorched.rb'

Scorched::Controller.config[:logger] = Logger.new(nil)

module Scorched
  class SimpleCounter
    def initialize(app)
      @app = app       
    end                

    def call(env)
      env['scorched.simple_counter'] ||= 0
      env['scorched.simple_counter'] += 1
      @app.call(env)   
    end                
  end
end

# We set our target application and rack test environment using let. This ensures tests are isolated, and allows us to
# easily swap out our target application.
module GlobalConfig
  extend RSpec::SharedContext
  let(:app) do
    Class.new(Scorched::Controller)
  end
  
  let(:rt) do
    Rack::Test::Session.new(app)
  end
  
  original_dir = __dir__
  before(:all) do
    Dir.chdir(__dir__)
  end
  after(:all) do
    Dir.chdir(original_dir)
  end
end

RSpec.configure do |c|
  c.alias_example_to :they
  # c.backtrace_clean_patterns = []
  c.include GlobalConfig
end