Middleware
==========

While middleware can be added in your _rackup_ file to wrap your Scorched application, it can be more desirable to add the middleware at the controller level. Scorched itself requires this as it needs to include a set of Rack middleware out-of-the-box. Developers can't be expected to manually add these to their rackup file for every Scorched application.

Like _filters_, middleware is inheritable thanks to it's use of the ``Scorched::Collection`` class. Also like _filters_, middleware proc's are only run once per request, which prevents unintended double-loading of middleware.

Adding middleware to a Scorched controller involves pushing a proc onto the end of the middleware collection, accessible via the ``middleware`` accessor method. The given proc is ``instance_exec``'d in the context of a Rack builder object, and so can be used for more than just loading middleware. 

    # ruby
    middleware << proc do
      use Rack::Session::Cookie, secret: 'blah'
      # Stolen from Rack's own documentation...
      map "/lobster" do
        use Rack::Lint
        run Rack::Lobster.new
      end
    end
