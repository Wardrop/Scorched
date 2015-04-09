Requests and Responses
======================
One of the first things a controller does when it instantiates itself, is make the Rack environment hash accessible via the `env` helper, as well as make available a `Scorched::Request` and `Scorched::Response` object under the respective `request` and `response` methods.

The `Scorched::Request` and `Scorched::Response` classes are children of the corresponding _Rack_ request and response classes, with a little extra functionality tacked on.

The _request_ object makes accessible all the information associated with the current request, such as the GET and POST data, server and environment information, request headers, and so on. The _response_ is much the same, but in reverse. You'll use the _response_ object to set response headers and manipulate the body of the response.

Refer to the _Rack_ documentation for more information on the `Rack::Request` and `Rack::Response` classes.


Scorched Extras
---------------
As mentioned, Scorched tacks a few extras onto it's `Scorched::Request` and `Scorched::Response` classes. Most of these extras were added as a requirement of the Scorched controller, but they're just as useful to other developers.

Refer to the API documentation for `Scorched::Request` and `Scorched::Response`.


Halting Requests
----------------
There may be instances we're you want to shortcut out-of processing the current request. The `halt` method allows you to do this, though it's worth clarifying its behaviour.

When `halt` is called within a route, it simply exits out of that route, and begins processing any _after_ filters. Halt can also be used within a _before_ or _after_ filter, in which case any remaining filters in the current controller are skipped, with the exception of _forced_ filters (see documentation on filters).

Calls to `halt` don't propagate up the controller chain. They're caught within the controller they're thrown. A call to `halt` is equivalent to doing a manual `throw :halt`. Calling `halt` is often preferred though because as well as being syntactically sweeter, it can take an optional argument to set the response status and body, which is something you likely want to do when halting a request.


Passing Requests
----------------
A route may _pass_ a request to the next matching route. _passing_ is very similar to halting, except an opportunity is given to other matching routes to fulfil the request. This is implemented as a throw/catch mechanism, much the same as `halt`. You can do a `throw :pass` manually, or use the helper method `pass`.

If a target passes a request, the request is still considered _unmatched_ or _unsatisfied_. Hence, if no other target matches the passed request, a 404 is returned as the response status by default.


Redirections
------------
A common requirement of many applications is to redirect requests to another URL based on some kind of condition. Scorched offers the very simple `redirect` method which takes one required argument - the absolute or relative URL to redirect to - and an optional response status, which defaults to either a 303 or 302 response status depending on the HTTP protocol version used for the request.