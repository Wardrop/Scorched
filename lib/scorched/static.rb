module Scorched
  class Static
    def initialize(app, dir = 'public')
      @app = app
      @file_server = Rack::File.new(dir)
    end

    def call(env)
      @file_server.call(env)
      response = @file_server.call(env)
      response[0] >= 400 ? @app.call(env) : response 
    end
  end
end
