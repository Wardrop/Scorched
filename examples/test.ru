require File.expand_path('../../lib/scorched.rb', __FILE__)

class MyApp < Scorched::Controller
  controller '/' do

  end
  
  after do
    p @_matched
  end
end
    
run MyApp