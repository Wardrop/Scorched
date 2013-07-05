require File.expand_path('../../lib/scorched.rb', __FILE__)

class MyApp < Scorched::Controller
  get '/*' do |part|
    p part
    part
  end
end
    
run MyApp