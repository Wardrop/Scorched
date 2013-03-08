Sharing and Managing Request State
==================================
Because Scorched allows sub-controllers to an arbitrary depth and treats all controllers equal (i.e has no concept of a _root_ controller), it means instance variables cannot be used to track, maintain or share request state between controllers. I mention this because instance variables are the most common way to manage the request state in some other frameworks, such as Sinatra.

The only data exchanged between controllers is the Rack environment hash. Using the Rack environment hash is the only thread-safe way to maintain and share the request state.

As an example, consider the Scorched implementation of flash session data. Flash session data must be shared between controllers throughout the life of the request, and hence the rack environment hash is the only solution.