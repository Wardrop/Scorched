require File.expand_path('../../lib/scorched.rb', __FILE__)

class App < Scorched::Controller
  get '/' do
    'root'
  end

  controller '/' do
    get '/login' do
      'login'
    end

    get '/logout' do
      'logout'
    end
  end
end

run App
