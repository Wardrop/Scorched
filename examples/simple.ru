require File.expand_path('../../lib/scorched.rb', __FILE__)

class App < Scorched::Controller
  get '/' do
    'hello world'
  end
end

run App
