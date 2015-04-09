The Controller
==============

Scorched consists almost entirely of the `Scorched::Controller`. The Controller is the class from which your application class inherits. All the code examples provided in the documentation are assumed to be wrapped within a controller class.

```ruby    
class MyApp < Scorched::Controller
  # We are now within the controller class.
  # Most examples are assumed to be within this context.
end
```

Your application's root controller (named `MyApp` in the example above), should be configured as the _run_ target in your rackup file:

```ruby
# config.ru
require './myapp.rb'
run MyApp
```

Sub-Controllers
---------------
One of the core features of Scorched is the fact that Controller's are intended to be inheritable and nestable as sub-controllers. This is perhaps the main advantage of Scorched over the likes of Sinatra and Padrino, and is one of the key innovations of the framework.

For the most part, you will find yourself breaking up your application into many discrete controllers. This will allow you to scope your configuration, filters, error handlers, and conditions, to logical groups of routes. This can save a lot of code repetition, keeping your code DRY, hence the name _Scorched_.

A sub-controller is any controller that's mapped by another controller. `ControllerB` in the following example, is one example of a sub-controller.

``` ruby
class ControllerA < Scorched::Controller
  get '/' do
    "Hello there"
  end
  
  after do
    response.body[0] << '.' # Always forgetting to add my periods
  end
end

class ControllerB < Scorched::Controller
  get '/' do
    "I'm apparently a sub-controller"
  end
end

ControllerA << {pattern: '/sub', target: ControllerB}
```

The  previous example is awfully crude, but it hopefully demonstrates that there's absolutely no magic happening here. In that previous example, a request for `/sub` will pass through `ControllerA` and onto `ControllerB`, before heading back out the way it came. Hence, a request for `/sub` will yield `I'm apparently a sub-controller.`; note the period added by ControllerA's _after_ filter (more on _after_ filters later).

While in the previous example, `ControllerB` counts as a sub-controller in that it's nested within ControllerA, at least from a routing perspective, `ControllerA` and `ControllerB` are completely unrelated; they share nothing.

A lot can be gained by not only nesting `ControllerB` within `ControllerA`, but by also inheriting from it.

``` ruby
class ControllerA < Scorched::Controller
  render_defaults[:dir] = 'views'
  render_defaults[:layout] = :main
  
  conditions[:user] = proc { |usernames|
    [*usernames].include? session['username']
  }
  
  
  get '/' do
    bold "Hello there"
  end
  
  def bold(str)
    "<strong>#{str}</strong>"
  end
end

class ControllerB < ControllerA
  render_defaults[:layout] = :controller_b
  
  get '/', user: 'bob' do
    bold "I'm apparently a sub-controller"
  end
end

ControllerA << {pattern: '/sub', target: ControllerB}
```

Now that `ControllerB` is inheriting from `ControllerA`, it not only gets access to all its methods, such as the very helpful `bold`, but it also inherits anything configured on `ControllerA`, such as rendering defaults, filters, middleware, conditions, etc. Very handy.

You can use nesting and inheritance exclusively, or together, depending on your needs.

Controller Helper
-----------------
There is a more succinct way of mapping and defining sub-controllers, and that's with the `controller` helper. Here's the previous example cut-down and re-written using the `controller` helper.

``` ruby
class MyApp < Scorched::Controller
  get '/' do
    bold "Hello there"
  end
  
  controller '/sub' do
    render_defaults[:layout] = :controller_b
  
    get '/', user: ['bob', 'jeff'] do
      bold "I'm apparently a sub-controller"
    end
  end
  
  def bold(str)
    "<strong>#{str}</strong>"
  end
end
```

The `controller` helper takes an optional URL pattern as it's first argument, an optional parent class as its second, and finally a mapping hash as its third optional argument, where you can define a priority, conditions, or override the URL pattern. Of course, the `controller` helper takes a block as well, which defines the body of the new controller class.

The optional URL pattern defaults to `'/'` which means it's essentially a match-all mapping. In addition, the generated controller has `:auto_pass` set to `true` by default (refer to configuration documentation for more information). This is a handy combination for grouping a set of routes in their own scope, with their own methods, filters, configuration, etc. 

``` ruby
class MyApp < Scorched::Controller
  get '/' do
    format "Hello there"
  end
  
  controller do 
    before { response['Content-Type'] = 'text/plain' }
  
    get '/hello' do
      'Hello'
    end
    
    def emphasise(str)
      "**#{str}**"
    end
  end
  
  get '/goodbye' do
   'Goodbye'
  end
  
  after { response.body = emphasise(response.body.join) }
  
  def emphasise(str)
    "<strong>#{str}</strong>"
  end
end
```

That example, while serving no practical purpose, hopefully demonstrates how you can combine various constructs with sub-controllers, to come up with DRY creative solutions.

Finally, the `controller` helper can also be used a shortcut to map one controller to another, where the given class is mapped directly, instead of being the parent of a new controller class. These two examples are essentially equivalent:

``` ruby
ControllerA << {pattern: '/sub', target: ControllerB}

# Or

class ControllerA
  controller '/', ControllerB # Note that no block was given
end
```


The Root Controller
-------------------
Although you will likely have a main controller to serve as the target for Rack, Scorched does not have the concept of a root controller. It makes no differentiation between a sub-controller and any other controller. All Controllers are made equal.

You can arrange and nest your controllers in any way, shape or form. Scorched has been designed to not make any assumptions about how you structure your controllers, which again, can accommodate creative solutions.
