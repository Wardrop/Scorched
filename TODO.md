To Do
=====
* Make specs for Collection and Options classes more thorough, e.g. test all non-reading modifiers such as clear, delete, etc.


Unlikely
========
These features are unlikely to be implemented unless someone provides good enough justification.

* Mutex locking option - I'm of the opinion that the web server should be configured for the concurrency model of the application, rather than the framework.
* Using Rack::Protection by default - The problem here is that a good portion of Rack::Protection involves sessions, and given that Scorched doesn't itself load any session middleware, these components of Rack::Protection would have to be excluded. I wouldn't want to lull anyone into a false sense of security
* Filter priorities - They're technically possible, but I believe it would introduce the potential for _filter hell_; badly written filters and mass hysteria. Filter order has to be logical and predictable. Adding prioritisation would undermine that, and make for lazy use of filters. By not having prioritisation, there's incentive to design filters to be order-agnostic.
* Verbose logging - I originally intended to add some form of debug-style logging to show the complete flow of a request as it traverses through filters and controllers, etc. For a couple of reasons, I've decided to leave this out of Scorched. For those unfamiliar with the order in which filters and routes are invoked, it's better to learn through first-hand experience writing little test applications, rather than depending on debug logging.
