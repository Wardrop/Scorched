Milestones
==========

Changelog
---------
### v0.7
* Logging preparations made. Now just have to decide on a logging strategy, such as what to log, how verbose the messages should be, etc.
* Environment-specific defaults added. The environment variable ``RACK_ENV`` is used to determine the current environment.
  * Non-Development
    * ``config[:static_dir] = false``
  * Development
    * ``config[:show_exceptions] = true``
    * ``config[:logger] = Logger.new(STDOUT)``
    * Add developer-friendly 404 error page. This is applied as an after filter, and won't have any effect if the response body is set.
* ``absolute`` method now returns forward slash if script name is empty.

### v0.6
* ``view_config`` options hash renamed to ``render_defaults`` which better reflects its function.

### v0.5.2
* Minor modification to routing to make it behave as a documented regarding matching at the directly before or on a path.
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



To Do
-----
Some of these remaining features may be broken out into a separate contributor library to keep the core lean and focused.

* Make specs for Collection and Options classes more thorough, e.g. test all non-reading modifiers such as clear, delete, etc.
* Add view helpers
  * Add helper to easily read and build HTTP query strings. Takes care of "?" and "&" logic, escaping, etc. This is
    intended to make link building easier.
  * Form populator implemented with Nokogiri. This would have to be added to a contrib library.
* Add Verbose logging, including debug logging to show each routing hop and the current environment (variables, mode, etc)
* Environment optimised defaults
  * Production
    * use Rack::Protection
    * Disable static file serving. Sub-controllers can obviously override this. This will just change the default.
  * Development
    * Log to STDOUT
    * use Rack::ShowExceptions
    * Add developer-friendly 404 error page.
    
Unlikely
--------
* Mutex locking option - I'm of the opinion that the web server should be configured for the concurrency model of the application, rather than the framework.
* Using Rack::Protection by default - The problem here is that a good portion of Rack::Protection involves sessions, and given that Scorched doesn't itself load any session middleware, these components of Rack::Protection would have to be excluded. I wouldn't want to invoke a false sense of security


More things will be added to these lists as they're thought of and considered.
