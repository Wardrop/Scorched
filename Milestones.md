Milestones
==========

Changelog
---------
### v0.11.1
* Fixed issue where multiple nested render calls would incorrectly render the layout (issue #9).
* Bumped Tilt dependancy to v1.4 and removed work-around for Tilt encoding issue.

### v0.11
* Route wildcards '*' and '**' (and their named equivalents) now match zero or more characters, instead of one or more. This means `/*` will now match both `/` and `/about` for example. 
* Conditions can now be inverted by appending an exclamation mark to the condition, e.g. `method!: 'GET'` matches all HTTP methods, excluding GET.
* While not strictly Scorched related, one planned feature for Scorched was to implement a simple form population mechanism. This has instead been implemented as a stand-alone project, [Formless](https://github.com/Wardrop/Formless), which can be used with any framework or application, including Scorched.

### v0.10
* Route matching internals have been refactored.
    * Match information is now stored in the `Match` struct for better formalisation.
    * `matches` method no longer has a short-circuit option, and now returns all mappings that match the URL, regardless of whether their conditions passed. It also now caches the set of matches which are returned on subsequent calls.
    * The first failed condition (if any) is stored in the `Match` struct as `:failed_condition`. This allows one to change the response in an after block depending on what condition failed. For example, proper status codes can be set depending on the failed condition.
    * Response status defaults to 403 if one or more mappings are matched, but their conditions do not pass. The existing behaviour was to always return 404.
* Added `:proc` condition which takes one or more Proc objects, allowing custom conditions to be added on-the-fly.
* Added `:matched` condition. When a controller delegates the request to a mapping, it's considered to be matched.
* Added `:failed_condition` condition. If one or more mappings are matched, but they're conditions do not pass, the first failed condition of the first matched mapping is considered the `failed_condition` for the request.
* Added `:config` condition which takes a hash, each element of which must match the value of the corresponding config option.
* Renamed `:methods` condition to `:method` for consistency sake.
* Added default error message for all empty responses with a HTTP status code between 400 and 599, inclusive.
* `Scorched::Collection` now merges parent values onto the beginning of self, rather than the end.
* To compensate for the previous change, an `append_parent` accessor added to `Scorched::Collection` to allow _after_ filters to run in the correct order, executing inner filters before outer filters.
* Added `:show_http_error_pages` config option. If true, it shows the Scorched HTTP error pages. Defaults to false.
* Filters have been added to set the appropriate HTTP status code for certain failed conditions, such as returning `405 Method Not Allowed` when for example, a POST is made to a URL that only accepts GET requests.

### v0.9
* Refactored `render` method:
    * All Scorched options are now keyword arguments, including `:locals` which was added as a proper render option.
    * Scorched options are no longer passed through to Tilt.
    * `:tilt` option added to allow options to be passed directly to Tilt, such as `:engine`
    * Unrecognised options are still passed through to Tilt for convenience.
* Added template caching using Tilt::Cache.
    * Added `:cache_templates` config option. Defaults to true except for development.

### v0.8
* Changed `controller` method signature to accept an optional URL pattern as the first argument.
* Implemented a pass mechanism to short-circuit out of the current match and invoke the next match.
* Added `:auto_pass` configuration option. When true, if none of the controller's mapping match the request, the controller will `pass` back to the outer controller without running any filters.
* Sub-controllers generated with the `controller` helper are automatically configured with `:auto_pass` set to `true`. This makes inline sub-controllers even more useful for grouping routes.

### v0.7
* Logging preparations made. Now just have to decide on a logging strategy, such as what to log, how verbose the messages should be, etc.
* Environment-specific defaults added. The environment variable `RACK_ENV`s used to determine the current environment.
    * Non-Development
        * `config[:static_dir] = false`   * Development
        * `config[:show_exceptions] = true`       * `config[:logger] = Logger.new(STDOUT)`       * Add developer-friendly 404 error page. This is implemented as an after filter, and won't have any effect if the response body is set.
* `absolute` method now returns forward slash if script name is empty.

### v0.6
* `view_config` options hash renamed to ` `render_defaults`ch better reflects its function.

### v0.5.2
* Minor modification to routing to make it behave as documented regarding matching a forward slash directly after or at the end of the matched path.
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
    * Keyword arguments instead of `*args`ombined with ` `Hash === args.last`  * Replaced instances of `__FILE__`ith ` `__dir__`Added expected Rack middleware, Rack::MethodOverride and Rack::Head.
    
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
Some of these remaining features may be reconsidered and either left out, or put into some kind of contrib library.

* If one or more matches are found, but their conditions don't pass, a 403 should be returned instead of a 404.
* Make specs for Collection and Options classes more thorough, e.g. test all non-reading modifiers such as clear, delete, etc.


Unlikely
--------
These features are unlikely to be implemented unless someone provides a good reason.

* Mutex locking option - I'm of the opinion that the web server should be configured for the concurrency model of the application, rather than the framework.
* Using Rack::Protection by default - The problem here is that a good portion of Rack::Protection involves sessions, and given that Scorched doesn't itself load any session middleware, these components of Rack::Protection would have to be excluded. I wouldn't want to invoke a false sense of security
* Filter priorities - They're technically possible, but I believe it would introduce the potential for _filter hell_; badly written filters and mass confusion. Filter order has to be logical and predictable. Adding prioritisation would undermine that, and make for lazy use of filters. By not having prioritisation, there's incentive to design filters to be order-agnostic.
* Verbose logging - I originally intended to add some form of debug-style logging to show the complete flow of a request as it traverses through filters and controllers, etc. For a couple of reasons, I've decided to leave this out of Scorched. For those unfamiliar with the order in which filters and routes are invoked, it's better to learn through first-hand experience writing little test applications, rather than depending on debug logging.


More things will be added as they're thought of and considered.
