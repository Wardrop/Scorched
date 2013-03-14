Milestones
==========

Changelog
---------
### v0.5.2
* Response content-type now defaults to "text/html;charset=utf-8", rather than empty.

### v0.5.1
* Added URL helpers, #absolute and #url
* Render helper now loads files itself as Tilt still has issues with UTF-8 files.

### v0.5
* Implemented view rendering using Tilt.
* Added session method for convenience, and implemented helper for flash session data.
* Added cookie helper for conveniently setting, retrieving and deleting cookies.
* Static file serving actually works now
  * Custom middleware Scorched::Static serves as a thin layer on top of Rack::File.
* Added specs for each configuration option.
* Using Ruby 2.0 features where applicable. No excuse not to be able to deploy on 2.0 by the time Scorched is ready for production.
  * Keyword arguments instead of ``*args`` combined with ``Hash === args.last``.
  * Replaced instances of __FILE__ with __dir__.
* Added expected Rack middleware, Rack::MethodOverride and Rack::Head.
    
### v0.4
* Make filters behave like middleware. Inheritable, but are only executed once.
* Improved implementation of Options and Collection classes

### v0.3 and earlier
* Basic request handling and routing
* String and Regex URL matching, with capture support
* Implemented route conditions
  * Added HTTP method condition which the route helpers depend on.
* Added route helpers
* Implemented support for sub-controllers
* Implement before and after filters with proper execution order.
* Configuration inheritance between controllers. This has been implemented as the Options class.
* Mechanism for including Rack middleware.
* Added more route conditions e.g. content-type, language, user-agent, etc.
* Provide means to `halt` request.
  * Added redirect helping for halting and redirecting request
* Mechanism for handling exceptions in routes and before/after filters.
* Added static resource serving. E.g. public folder.



Remaining
---------
Some of these remaining features may be broken out into a separate contributor library to keep the core lean and focused.

* Make specs for Collection and Options classes more thorough, e.g. test all non-reading modifiers such as clear, delete, etc.
* Add view helpers
  * Add helper to easily read and build HTTP query strings. Takes care of "?" and "&" logic, escaping, etc. This is
    intended to make link building easier.
  * Form populator
* Provide a default error page somewhat similar to what Sinatra has.
* Add debug logging to show each routing hop and the current environment (variables, mode, etc)
* Environment optimised defaults
  * Production
    * Rack::Protection
    * Disable static file serving
  * Development
    * Verbose logging to STDOUT
    * use Rack::ShowExceptions
    
Unlikely
--------
* Mutex locking option? I'm of the opinion that the web server should be configured for the concurrency model of the application, rather than the framework.

    
More things will be added to these lists as they're thought of and considered.
