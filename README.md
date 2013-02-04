scorched
========

Light-weight, DRY as a desert, web framework for Ruby. Inspired by Sinatra, this framework is my vision of the next evolutionary step in light-weight ruby web frameworks.

The majority of core API design and implemention planning are complete. I'm currently implementing the frameworks core, which is it's routing and dispatching, which includes controllers, routing, request and response boilerplate, etc. First commit to github will be made once core functionality is complete and useable (v0.1).

Below I present a sample of the API as it currently stands:

    class MyApp < Scorched::Controller

      # From the most simple route possible...
      get '/' do
        "Hello World"
      end
      
      # To something that gets the muscle's flexing a little
      route '/articles/:title', '/articles/:title/::options' priority: 2, methods: ['GET', 'POST'], content_type: :json do
        # Do what you want in here
      end
      
      # Anonymous controllers allow for convenient route grouping to which filters and request/response defaults can be applied.
      controller do
        provides :json
        
        get '/articles/*?' do |page|
          [
            {title: 'Scorched Rocks', body: '...', created_at: '27/08/2012', created_by: 'Bob'}
          ]
        end
        
        after do
          response.to_json
        end
      end
      
      # The things you get for free by using Classes for Controllers (...that's directed at you Padrino)
      def my_little_helper
        # Do some crazy awesome stuff that no route can resist using.
      end
      
      # You can always avoid the routing helpers and add mappings manually. Anything that responds to #call is a valid target.
      self << {url: '/admin', priority: 10, target: My3rdPartyAdminApp}
      self << {url: '**', conditions: {maintenance_mode: true}, target: proc { |env|
        env['rack.response'].body << 'Maintenance underway, please be patient.'
      }}
    end
    
This API shouldn't look too foreign to anyone familiar with frameworks like Sinatra, and the potential power at hand should be obvious. The `route` method demonstrates a few minor features of Scorched:

* Multi-method routes - Because sometimes the difference between a GET and POST can be a single line of code. If no methods are provided, the route receives all HTTP methods.
* Multiple URL's - For the same reason as allowing a route to handle multiple methods, Scorched allows one to define multiple URL's on a route.
* Named Wildcards - Not an original idea, but you may note the named wildcard with the double colon. This maps to the '**' glob directive, which will span forward-slashes while matching. The single asterisk (or colon) behaves like the single asterisk glob directive, and will not match forward-slashes.
* Route priorities - Routes (referred to as mappings internally) can be assigned priorities. A priority can be any arbitrary number by which the routes are ordered. The higher the number, the higher the priority.
* Conditions - Conditions are merely procs defined on the controller which are inherited (and can be overriden) by child controllers. When a request comes in, mmapings that match the requested URL first have their conditions evaluated in the context of the controller instance before control is handed off to the target associated with that mapping. It's a very simple implementation that comes with a lot of potential.

That should hopefully give you an example of how the core of Scorched is shaping up. This demonstrates only a subset of what Scorched will offer.