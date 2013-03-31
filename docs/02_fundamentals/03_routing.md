Routing
=======

When Scorched receives a request, the first thing it does is iterate over it's internal mapping hash, looking for the any URL pattern that matches the current URL. If it finds an appropriate match, it invokes the `call` method on the target defined for that mapping, unless the target is a `Proc`, in which case it's invoked via `instance_exec` to run it within the context of the controller instance.

Mappings can be defined manually using the `map` class method, also aliased as `<<`. Besides the required URL pattern and target elements, a mapping can also define a priority, and one or more conditions. The example below demonstrates the use of all of them.

```ruby
map pattern: '/', priority: -99, conditions: {method: ['POST', 'PUT', 'DELETE']}, target: proc { |env|
  [200, {}, 'Bugger off']
}
```

The position the new mapping is inserted into the mapping hash is determined by it's priority, and the priority of the mappings already defined. This avoids re-sorting the mapping hash every time it's added to. This isn't a performance consideration, but is required to maintain the natural insert order of the mappings which have identical priorities (such as the default 0).

A `mapping` method is also provided as means to access all defined mappings on a controller, but it should be considered read-only for the reasons just stated.

Route Helpers
-------------
Adding mappings manually can be a little verbose and painful, which is why Scorched includes a bunch of route helpers which are used in most code examples.

The main route helper which all others delegate to, is the `route` class method. Here's what it looks like in both it's simple and advance form:

```ruby
route '/' do
  'Well hello there'
end

route '/*', 5, method: ['POST', 'PUT', 'DELETE'] do |capture|
  "Hmm trying to change #{capture} I see"
end
```

You can see pretty clearly how these examples correspond to the pattern, priority, conditions and target options of a manual mapping. The pattern, priority and conditions behave exactly as they do for a manual mapping, with a couple of exceptions.

The first exception is that the pattern must match to the end of the request path. This is mentioned in the _pattern matching_ section below.

The other more notable exception is in how the given block is treated. The block given to the route helper is wrapped in another proc. The wrapping proc does a couple of things. It first sends all the captures in the url pattern as argument to the given block, this is shown in the example above. The other thing it does is takes care of assigning the return value to the body of the response.

In the latter of the two examples above, a `:method` condition defines what methods the route is intended to process. The first example has no such condition, so it accepts all HTTP methods. Typically however, a route will handle a single HTTP method, which is why Scorched also provides the convenience helpers: `get`, `post`, `put`, `delete`, `head`, `options`, and `patch`. These methods automatically define the corresponding `:method` condition, with the `get` helper also including `head` as an accepted HTTP method.

Pattern Matching
----------------
All patterns attempt to match the remaining unmatched portion of the _request path_; the _request path_ being Rack's
`path_info` request variable. The unmatched path will always begin with a forward slash if the previously matched portion of the path ended immediately before, or included as the last character, a forward slash. As an example, if the request was to "/article/21", then both "/article/" => "/21" and "/article" => "/21" would match.

All patterns must match from the beginning of the path. So even though the pattern "article" would match "/article/21", it wouldn't count as a match because the match didn't start at a non-zero offset.

If a pattern contains named captures, unnamed captures will be lost - this is how named regex captures work in Ruby. So if you name one capture, make sure you name any other captures you may want to access.

Patterns can be defined as either a String or Regexp.

###String Patterns
String patterns are compiled into Regexp patterns corresponding to the following rules:

* `*` - Matches all characters excluding the forward slash.
* `**` - Matches all characters including the forward slash.
* `:param` - Same as `*` except the capture is named to whatever the string following the single-colon is.
* `::param` - Same as `**` except the capture is named to whatever the string following the double-colon is.
* `$` - If placed at the end of a pattern, the pattern only matches if it matches the entire path. For patterns defined using the route helpers, e.g. `Controller.route`, `Controller.get`, this is implied. 

###Regex Patterns
Regex patterns offer more power and flexibility than string patterns (naturally). The rules for Regex patterns are identical to String patterns, e.g. they must match from the beginning of the path, etc. 


Conditions
----------
Conditions are essentially just pre-requisites that must be met before a mapping is invoked to handle the current request. They're implemented as `Proc` objects which take a single argument, and return true if the condition is satisfied, or false otherwise. Scorched comes with a number of pre-defined conditions included, many of which are provided by _rack-accept_ - one of the few dependancies of Scorched.

* `:charset` - Character sets accepted by the client.
* `:config` - Takes a hash, each element of which must match the value of the corresponding config option.
* `:encoding` - Encodings accepted by the client.
* `:failed_condition` - If one or more mappings are matched, but they're conditions do not pass, the first failed condition of the first matched mapping is considered the `failed_condition` for the request.
* `:host` - The host name (i.e. domain name) used in the request.
* `:language` - Languages accepted by the client.
* `:media_type` - Media types (i.e. content types) accepted by the client.
* `:matched` - Whether a mapping in the controller instance was invoked as the target for the request.
* `:method` - The request method used, e.g. GET, POST, PUT, ... .
* `:proc` - An on-the-fly condition to be evaluated in the context of the controller instance. Should return true if the condition was satisfied, or false otherwise.
* `:user_agent` - The user agent string provided with the request. Takes a Regexp or String.
* `:status` - The response status of the request. Intended for use by _after_ filters.

Like configuration options, conditions are implemented using the `Scorched::Options` class, so they're inherited and can be overridden by child classes. You may easily add your own conditions as the example below demonstrates.

```ruby
condition[:has_permission] = proc { |v|
  user.has_permission == v
}

get '/', has_permission: true do
  'Welcome'
end

get '/', has_permission: false do
  'Forbidden'
end
```

Each of the built-in conditions can take a single value, or an array of values, with the exception of the `:host` and `:user_agent` conditions which support Regexp patterns.
