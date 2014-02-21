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

A `mappings` method is also provided as means to access all defined mappings on a controller, but it should be considered read-only for the reasons just stated.

Route Helpers
-------------
Adding mappings manually can be a little verbose and painful, which is why Scorched includes a bunch of route helpers which are used in most code examples.

The main route helper which all others delegate to, is the `route` class method. Here's what it looks like in both it's simple and advance forms:

```ruby
route '/' do
  'Well hello there'
end

route '/*', 5, method: ['POST', 'PUT', 'DELETE'] do |capture|
  "Hmm, I see you're trying to change the resource #{capture}"
end
```

You can see pretty clearly how these examples correspond to the pattern, priority, conditions and target options of a manual mapping. The pattern, priority and conditions behave exactly as they do for a manual mapping, with a couple of exceptions.

The first exception is that the pattern must match to the end of the request path. This is mentioned in the _pattern matching_ section below. You can also define a route with multiple patterns by using an array. This creates a different mapping for each URL, but using the same proc object and other arguments.

The other more notable exception is in how the given block is treated. The block given to the route helper is wrapped in another proc. The wrapping proc does a couple of things. It first sends all the captures in the url pattern as arguments to the given block; this is shown in the example above. The other thing it does is takes care of assigning the return value to the body of the response.

In the latter of the two examples above, a `:method` condition defines what methods the route is intended to process. The first example has no such condition, so it accepts all HTTP methods. Typically however, a route will handle a single HTTP method, which is why Scorched also provides the convenience helpers: `get`, `post`, `put`, `delete`, `head`, `options`, `patch`, `link` and `unlink`. These methods automatically define the corresponding `:method` condition, with the `get` helper also including `head` as an accepted HTTP method.

Pattern Matching
----------------
All patterns attempt to match the remaining unmatched portion of the _request path_; the _request path_ being Rack's
`path_info` request variable. The unmatched path will always begin with a forward slash if the previously matched portion of the path ended immediately before, or included as the last character, a forward slash. As an example, if the request was to "/article/21", then both "/article/" => "/21" and "/article" => "/21" would match.

The `path_info` used to match against is unescaped, meaning percent-codes are resolved, e.g. `%20` resolves to a space. The two exceptions are the escaped forward-slash and percent sign, which remain escaped as `%2F` and `%25` respectively.

> The forward-slash cannot be automatically escaped as it would make it impossible to disambiguate from an actual forward-slash in the URL (which has special meaning). The encoded percent-sign thus also needs to remain unescaped, otherwise it'd be impossible to safely unescape the escaped forward-slash in your application, if you needed to. If this all sounds very confusing, rest assured you probably won't ever encounter a scenario in which you'd have to think about this.

All patterns must match from the beginning of the path. So even though the pattern "article" would match "/article/21", it wouldn't count as a match because the match didn't start at a non-zero offset.

If a pattern contains named captures, unnamed captures will be lost - this is how named regex captures work in Ruby. So if you name one capture, make sure you name any other captures you may want to access.

Patterns can be defined as either a String or Regexp.

###String Patterns
String patterns are compiled into Regexp patterns corresponding to the following rules:

* `*` - Matches one or more characters, excluding the forward slash.
* `**` - Matches one or more characters, including the forward slash.
* `:param` - Same as `*` except the capture is named to whatever the string following the single-colon.
* `::param` - Same as `**` except the capture is named to whatever the string following the double-colon.
* `?` - If placed directly after a wildcard capture, matches zero or more characters instead of one or more. For example, the patterns `/*?` and `/::title?` would match both `/` and `/about`.
* `$` - If placed at the end of a pattern, the pattern only matches if it matches the entire path. For patterns defined using the route helpers, e.g. `Controller.route`, `Controller.get`, this is implied.

###Regex Patterns
Regex patterns offer more power and flexibility than string patterns (naturally). The rules for Regex patterns are identical to String patterns, e.g. they must match from the beginning of the path, etc. 

Captures
--------
Captures can be accessed as arguments on the route proc, or via the `captures` helper method, which is shorthand for `request.captures`.

```ruby
get '/:id' do |id|
  id == captures[:id]
end

get '/*/*' do |id, title|
  [id, title] == captures
end
```

The above examples demonstrates the two methods of accessing captures, for both named and anonymous captures. You may notice that while named and anonymous captures are passed to the proc as arguments in the exact same way, the `captures` helper either returns either a `Hash` or an `Array` depending on whether the captures are named or not.

Conditions
----------
Conditions are essentially just pre-requisites that must be met before a mapping is invoked to handle the current request. They're implemented as `Proc` objects which take a single argument, and return true if the condition is satisfied, or false otherwise. Scorched comes with a number of pre-defined conditions included, some of which use functionality provided by _rack-accept_ - one of the few dependancies of Scorched.

* `:charset` - Character sets accepted by the client.
* `:config` - Takes a hash, each element of which must match the value of the corresponding config option.
* `:content_type` - The content-type of the body of the request. E.g. "multipart/form-data", "application/json"
* `:encoding` - Encodings accepted by the client.
* `:failed_condition` - If one or more mappings are matched, but they're conditions do not pass, the first failed condition of the first matched mapping is considered the `failed_condition` for the request.
* `:host` - The host name (i.e. domain name) used in the request.
* `:language` - Languages accepted by the client.
* `:media_type` - Media types (i.e. content types) accepted by the client.
* `:handled` - Whether a mapping in the controller instance was invoked as the target for the request. A mapping that _passes_ a request is not considered a match.
* `:method` - The request method used, e.g. GET, POST, PUT, ... .
* `:proc` - An on-the-fly condition to be evaluated in the context of the controller instance. Should return true if the condition was satisfied, or false otherwise.
* `:user_agent` - The user agent string provided with the request. Takes a Regexp or String.
* `:status` - The response status of the request. Intended for use by _after_ filters.

As of v0.11, Scorched also supports inverted/negated conditions by adding a trailing exclamation mark. For example, a route with the condition `method!: 'GET'` will match any HTTP request except for `GET` requests.

Like configuration options, conditions are implemented using the `Scorched::Options` class, so they're inherited and can be overridden by child classes. You may easily add your own conditions as the example below demonstrates.

```ruby
conditions[:has_permission] = proc { |v|
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
