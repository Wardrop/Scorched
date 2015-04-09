require File.expand_path('../../lib/scorched.rb', __FILE__)

class App < Scorched::Controller
  get '/:name' do
    @message = greeting(captures[:name])
    render :hello
  end

  def greeting(name)
    "Howdy #{name}"
  end
end

run App
