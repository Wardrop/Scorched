module Scorched
  class Static
    def initialize(app, dir = 'public')
      @app, @dir = app, dir
    end

    def call(env)
      response = file_server.call(env)
      response[0] >= 400 ? @app.call(env) : response
    end

  protected

    def file_server
      @file_server ||= Rack::File.new(@dir)
    end
  end
end
