[Simple, Powerful, Scorched](https://scorchedrb.com)
==========================

Scorched is a generic, unopinionated, DRY, light-weight web framework for Ruby. It provides a generic yet powerful set of constructs for processing HTTP requests, with which websites and applications of almost any scale can be built.

If you've used a light-weight DSL-based Ruby web framework before, such as Sinatra, Scorched should look quite familiar. Scorched is a true evolutionary enhancement of Sinatra, with more power, focus, and less clutter.

Getting Started
---------------

Install the canister...

```console
$ gem install scorched
```

Open the valve...

```ruby
# hello_world.ru
require 'scorched'
class App < Scorched::Controller
  get '/' do
    'hello world'
  end
end
run App
```

And light the flame...

```console
$ rackup hello_world.ru
```

#### A Note on Requirements

Scorched requires Ruby 2.0 or above. If you've got Ruby 2.0.0-p195 and newer, you're good. Otherwise, you need to ensure that your version of Ruby 2.0 includes [changeset 39919](http://bugs.ruby-lang.org/projects/ruby-trunk/repository/revisions/39919) in order to avoid suffering from [random segmentation faults](http://bugs.ruby-lang.org/issues/8100).


The Errors of Our Past (and Present!)
----------------------
One of the mistakes made by a lot of other Ruby frameworks is to not leverage the power of the class. Consequently, this makes for some awkwardness. Helpers for example, are a classic reinvention of what classes and modules are already made to solve. Scorched implements Controllers as classes, which in addition to having their own DSL, allow you to define and call whatever you need as standard instance methods. The decision to allow developers to implement helpers and other common functionality as standard instance methods not only makes Controllers somewhat more predictable and familiar, but also allows for such helpers to be inheritable via plain old class inheritance.

Another design oversight of other frameworks is the lack of consideration for the hierarchical nature of websites and the fact that it's often desireable for sub-directories to inherit attributes of their parents. Scorched supports sub-controllers to any arbitrary depth, with each controller's configuration, filters, route conditions, etc. applied along the way. This can help in many areas of web development, including security, restful interfaces, and interchangeable content types.


Design Philosophy
-----------------
Scorched has a relatively simple design philosophy. The main objective is to keep Scorched lean and generic. Scorched refrains from expressing any opinion about how you should design and structure your application. The general idea is to give developers the constructs to quickly put together small, medium and even large websites and applications.

There is little need for a framework to be opinionated if the opinions of the developer can be quickly and easily built into it on a per-application basis. To do this effectively, developers will really need to understand Scorched, and the best way to facilitate that is to lower the learning curve, by keeping the core design logical, predictable and concise.


Magicians Not Welcome
---------------------
Scorched aims to be raw and transparent. Magic has no place. A thoughtful and simple design means there's no requirement for magic. Because of that, most developers should be able to master Scorched in an evening.

Part of what keeps Scorched lightweight is that unlike other lightweight web frameworks that attempt to hide Rack in the background, Scorched makes no such attempt, very rarely providing functionality that overlaps with what's already provided by Rack. In fact, familiarity with Rack is somewhat of a pre-requisite to mastering Scorched.


First Impressions
-----------------

```ruby
class MyApp < Scorched::Controller

  # From the most simple route possible...
  get '/' do
    "Hello World"
  end

  # To something that gets the muscle's flexing
  route '/articles/:title/::opts', 2, method: ['GET', 'POST'], content_type: :json do
    # Do what you want in here. Note, the second argument is the optional route priority.
  end

  # Anonymous controllers allow for convenient route grouping to which filters and conditions can be applied
  controller conditions: {media_type: 'application/json'} do
    get '/articles/*' do |page|
      {title: 'Scorched Rocks', body: '...', created_at: '27/08/2012', created_by: 'Bob'}
    end

    after do
      response.body = response.body.to_json
    end
  end

  # The things you get for free by using Classes for Controllers (...that's directed at you Padrino)
  def my_little_helper
    # Do some crazy awesome stuff that no route can resist using.
  end

  # You can always avoid the routing helpers and add mappings manually. Anything that responds to #call is a valid
  # target, with the only minor exception being that proc's are instance_exec'd, not call'd.
  self << {pattern: '/admin', priority: 10, target: My3rdPartyAdminApp}
  self << {pattern: '**', conditions: {maintenance_mode: true}, target: proc { |env|
    @request.body << 'Maintenance underway, please be patient.'
  }}
end
```

This API shouldn't look too foreign to anyone familiar with frameworks like Sinatra, and the potential power at hand should be obvious. The `route` method demonstrates a few minor features of Scorched:

* Multi-method routes - Because sometimes the difference between a GET and POST can be a single line of code. If no methods are provided, the route receives all HTTP methods.
* Named Wildcards - Not an original idea, but you may note the named wildcard with the double colon. This maps to the '**' glob directive, which will span forward-slashes while matching. The single asterisk (or colon) behaves like the single asterisk glob directive, and will not match forward-slashes.
* Route priorities - Routes (referred to as mappings internally) can be assigned priorities. A priority can be any arbitrary number by which the routes are ordered. The higher the number, the higher the priority.
* Conditions - Conditions are merely procs defined on the controller which are inherited (and can be overriden) by child controllers. When a request comes in, mappings that match the requested URL, first have their conditions evaluated in the context of the controller instance, before control is handed off to the target associated with that mapping. It's a very simple implementation that comes with a lot of flexibility.

Comparisons with other frameworks
---------------------------------
Refer to the [comparisons](https://github.com/Wardrop/Scorched/tree/master/comparison) directory in the repo to compare a simple example app written in frameworks similar to Scorched.

Links
-----
* [Website](https://scorchedrb.com)
* [Online API Reference](https://rubydoc.info/gems/scorched)
* [GitHub Project](https://github.com/wardrop/Scorched)
* [Issue Tracker](https://github.com/wardrop/Scorched/issues)
* [Discussion/Mailing List](https://groups.google.com/d/forum/scorched)
