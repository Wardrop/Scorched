Requests and Responses
======================
One of the first things a controller does when it instantiates itself, is make the Rack environment hash accessible via the ``env`` helper, as well as make available a ``Scorched::Request`` and ``Scorched::Response`` object under the respective ``request`` and ``response`` methods.

The ``Scorched::Request`` and ``Scorched::Response`` classes are children of the corresponding _Rack_ request and response classes, with a little extra functionality tacked on.

The _request_ object makes accessible all the information associated with the current request, such as the GET and POST data, server and environment information, request headers, and so on. The _response_ is much the same, but in reverse. You'll use the _response_ object to set response headers and manipulate the body of the response.

Refer to the _Rack_ documentation for more information on the ``Rack::Request`` and ``Rack::Response`` classes.


Scorched Extras
---------------
As mentioned, Scorched tacks a few extras onto it's ``Scorched::Request`` and ``Scorched::Response`` classes. Most of these extras were added as a requirement of the Scorched controller, but they're just as useful to web developers and therefore worth knowing about.

Refer to the generated API documentation.