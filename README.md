scorched
========

Light-weight, DRY as a desert, web framework for Ruby. Inspired by Sinatra, this framework is my vision of the next evolutionary step in light-weight ruby web frameworks.

The majority of core API design and implemention planning are complete. I'm currently implementing the frameworks core, which is it's routing and dispatching, which includes controllers, request and response boilerplate, etc. First commit to github will be made once core functionality is complete and useable (v0.1).

Below I present a sample of the kind of API I'm going for, at least for routing:

    class MyApp < Scorched::Controller

      # From the most simple route possible...
      get '/' do
        "Hello World"
      end
      
      # To something that gets the muscle's flexing a little
      route '/articles/:title/::options', '/article_index/:article_id', priority: 2, methods => ['GET', 'POST'] conditions: {content_type: :json} do
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
      
      # The things you get for free by using Classes for Controllers (...that's at you Padrino)
      def my_little_helper
        # Do some crazy awesome stuff that no route can resist using.
      end
      
      self << {url: '/admin', priority: 10, target: My3rdPartyAdminApp}
      self << {url: '**', conditions: {maintenance_mode: true}, target: proc { |env|
        env['rack.response'].body << 'Maintenance underway, please be patient.'
      }}
    end
    
This API shouldn't look too foreign to anyone familiar with frameworks like Sinatra, and the potential power at hand should be obvious. Something that may not make immediate sense is the `route` method we see used. This demonstrates a few minor features:

* Multi-method routes - Because sometimes the difference between a GET and POST can be a single line of code. If no methods are provided, the route receives all HTTP methods.
* Multiple URL's - By default, if more than one URL is provided, the first is considered the canonical URL to which all the other URL's specified redirect to. Nice for remapping legacy URL's and for supporting multiple interfaces to your website or application (e.g. referencing an article by title or ID).
* Named Wildcards - Not an original idea, but you may note the named wildcard with the double colon. This maps to the '**' glob directive, which will span forward-slashes while matching. The single asterisk (or colon) behaves like the single asterisk glob directive, and will not match forward-slashes.
* Route priorities - Routes (referred to as mappings internally) can be assigned priorities. A priority can be any arbitrary number by which the routes are ordered. The higher the number, the higher the priority.

At the bottom of the class definition demonstrates how one can map rack-callable objects with all the same power as routes, which remember are nothing more than proc objects like the maintenance mapping above.

That should hopefully give you an example of how the core of Scorched is shaping up.