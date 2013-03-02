Scorched
========

*Light-weight, DRY as a desert, web framework for Ruby. Inspired by Sinatra, this framework is my vision of the next evolutionary step in light-weight ruby web frameworks.*

Scorched honours the patrons of the past. It's not a complete reinvention of the lightweight web framework, but rather what I hope is an evolutionary enhancement. Most of the concepts are carried forward from predecessors. Scorched merely enhances those concepts in an attempt to extract their full potential, as well as offering up to scrutiny some entirely new idioms. All with the intention to make developing lightweight web apps in Ruby even more enjoyable.

The name 'Scorched' is inspired by the main goal of the project, which is to DRY-up what the likes of Sinatra and Padrino left moist.


The Errors of Our Past (aka. Areas of Moisty-ness)
--------------------------------------------------
I think the biggest mistake made by the predecessors of Scorched such as Sinatra/Padrino, was to not leverage the power
of the class. The consequences of this made for some awkwardness. Helpers are a classical reinvention of what
classes and modules were already made to solve. Scorched implements Controllers as Classes, which in addition to having their own DSL, allow defining and calling traditional class methods. Allowing developers to implement helpers and other common functionality as proper methods not only makes them more predictable and familiar, but of course allow such helpers to be inheritable via plain-old Class inheritance.

Perhaps another error (or area of sogginess, if you will) has been a lack of consideration for the hierarchical nature of websites, and the fact that sub-directories are often expected to inherit attributes of their parents. Scorched supports sub-controllers to any arbitrary depth, with each controllers filters and route conditions applied along the way. This can assist many areas of web development, including security, restful interfaces, and interchangeable output formats.


Design Philosophy
-----------------
Scorched has a relatively simple design philosophy. The main objective is to keep Scorched lean and generic. Scorched refrains from expressing too much opinion. The general idea behind Scorched is to give developers all the tools to quickly put together small, medium and perhaps even large websites and applications.

There's little need for a framework to be opinionated if the opinions of the developer can be quickly and easily built into it on a per-application basis. To do this effectively, developers really need to understand Scorched, and the best way to lower facilitate that is to lower the learning curve by keeping the core design, logical, predictable, and concise. 


First Impressions
-----------------
Below I present a sample of the API as it currently stands:

    class MyApp < Scorched::Controller

      # From the most simple route possible...
      get '/' do
        "Hello World"
      end
      
      # To something that gets the muscle's flexing a little
      route '/articles/:title/::opts', 2, methods: ['GET', 'POST'], content_type: :json do
        # Do what you want in here. Note, the second argument is the optional route priority.
      end
      
      # Anonymous controllers allow for convenient route grouping to which filters and conditions can be applied
      controller conditions: {content_type: :json} do
        get '/articles/*' do |page|
          {title: 'Scorched Rocks', body: '...', created_at: '27/08/2012', created_by: 'Bob'}
        end
        
        after do
          response.to_json
        end
      end
      
      # The things you get for free by using Classes for Controllers (...that's directed at you Padrino)
      def my_little_helper
        # Do some crazy awesome stuff that no route can resist using.
      end
      
      # You can always avoid the routing helpers and add mappings manually. Anything that responds to #call is a valid target, with the only minor exception being that proc's are instance_exec'd, not #call'd.
      self << {url: '/admin', priority: 10, target: My3rdPartyAdminApp}
      self << {url: '**', conditions: {maintenance_mode: true}, target: proc { |env|
        @request.body << 'Maintenance underway, please be patient.'
      }}
    end
    
This API shouldn't look too foreign to anyone familiar with frameworks like Sinatra, and the potential power at hand should be obvious. The `route` method demonstrates a few minor features of Scorched:

* Multi-method routes - Because sometimes the difference between a GET and POST can be a single line of code. If no methods are provided, the route receives all HTTP methods.
* Named Wildcards - Not an original idea, but you may note the named wildcard with the double colon. This maps to the '**' glob directive, which will span forward-slashes while matching. The single asterisk (or colon) behaves like the single asterisk glob directive, and will not match forward-slashes.
* Route priorities - Routes (referred to as mappings internally) can be assigned priorities. A priority can be any arbitrary number by which the routes are ordered. The higher the number, the higher the priority.
* Conditions - Conditions are merely procs defined on the controller which are inherited (and can be overriden) by child controllers. When a request comes in, mappings that match the requested URL, first have their conditions evaluated in the context of the controller instance, before control is handed off to the target associated with that mapping. It's a very simple implementation that comes with a lot of potential.

That should hopefully give you an example of how the core of Scorched is shaping up. This demonstrates only a subset of what Scorched will offer.


Development Progress
--------------------
Please refer to [Milestones.md](Milestones.md) for a breakdown of development progress.
