module Scorched
  class Static
    def initialize(app, options={})
      @app = app
      @options = options
      dir = options.delete(:dir) || 'public'
      options[:cache_control] ||= 'no-cache'
      @file_server = Rack::File.new(dir, options)
    end

    def call(env)
      response = @file_server.call(env)
      response[0] >= 400 ? @app.call(env) : response 
    end
  end
end