Changelog
=========

_Note that Scorched is yet to reach a v1.0 release. This means breaking changes may still be made. If upgrading the version of Scorched for your project, review this changelog carefully._

### v0.22
* The `redirect` method now passes the given URL through `absolute`.
* The error page filter now always runs at the end-point controller so `:show_http_error_pages` behaves as expected when overriden in sub-controllers.

### v0.21
* Named captures have changed again. The values are now passed as arguments to route proc's in favor of using the new `captures` convenience method for accessing named arguments as a hash.
* The `:redirect` option for `:strip_trailing_slashes` no longer cause a redirection loop when the request path is set to two or more forward slashes, e.g. '//'
* Changed default value of `render_defaults[:tilt]` to `{default_encoding: 'UTF-8'}`. This defaults _Tilt_ to using UTF-8 for loading template files, which is desirable 99% of the time.
* The `action` method has been split out into two new methods, `process` and `dispatch`. This provides the oppurtunity to override the dispatch logic where more control is needed over how mapping targets are invoked.
* `:failed_condition` condition now takes into account whether any mapping has actually handled the request. This allows for example, the correct status to be set when a mapping has been matched, but has `pass`ed the request.

### v0.20
* _After_ filters are now still processed when a request is halted. This restores the original behaviour prior to version 0.8. This fixes an issue where halting the request after setting flash session data would cause the request to bomb-out.
* As an extension of the change above, filters can now be marked as _forced_ using the new `force` option, which if true, means the filter will run even if the request is halted within another filter (including within another forced filter). This ensures a particular filter is run for every request. This required changing the public interface for the _filter_ method. The sugar methods _before_, _after_, and _error_ have remained backwards compatible. 
* Named captures are now passed to route proc's as a single hash argument. The previous behaviour was an oversight.
* Halting within an error filter is now swallowed if the error filter is invoked by an error raised in a before or after filter.
* The `controller` helper can now be used to map predefined controllers simply by omitting the block, which is now optional. This a more convenient means of mapping controllers as compared to the more barebones `map` method.
* `log` method now returns the log object. Method arguments are also now optional, meaning you can use the more natural logger interface if you prefer, e.g. `log.info "hello"`.

### v0.19
* The behaviour of wildcards `*` and `**` (and their _named_ equivalents) have been reverted to their original behaviour of matching one or more characters, instead of zero or more. This means `/*` will no longer match `/`. Adding a question mark directly after a wildcard will have that wildcard match zero or more character, instead of one or more. So the pattern `/*?` will match both `/` and `/about`.

### v0.18
* Redirects now use a 303 or 302 HTTP status code by default, depending on HTTP version (similar logic to Sinatra). Trailing slash redirects (triggered by :strip_trailing_slash) still uses a 307 status.

### v0.17
* Fixes an issue introduced in v0.16 where joining `SCRIPT_NAME` and `PATH_INFO` would sometimes produce a path with two forward slashes, and a related issue where `PATH_INFO` would sometimes be missing a leading forward slash when it should have had one.
* Mappings are now sorted by the best matching `media type` in addition to the existing logic that included definition order and priority. This required that mappings be sorted at request-time rather than at the time they're mapped. Note, because of limitations of `rack-accept`, this doesn't completely respect the HTTP spec when it comes to prioritising which media type to serve for a given request. Full support for the HTTP spec is intended for a future release.
* File path references to views are now joined to the view directory using #expand_path. This allows views to be specified with an absolute path (effectively ignoring the view directory), and better support for relative paths.

### v0.16
* A copy of the Rack env hash is now handed off to sub-controllers and other Rack-callable objects, with `PATH_INFO` and `SCRIPT_NAME` now set to appropriate values, bring Scorched inline with the Rack specification. This differs from the original behaviour which was to just forward on the original env hash unmodified.
* URL helper method `absolute` and `url` now use the new env property `scorched.root_path` as their base path, rather than `SCRIPT_NAME`.
* Helpers for HTTP methods `link` and `unlink` have been added.

### v0.15
* Route DSL methods (`route`, `get`, `post`, ...) now accept an array of patterns as the pattern argument. Each pattern is defined as a separate mapping, sharing the same target proc. This provides a cleaner and more efficient solution to simply wrapping a route definition within a loop.
* URI unescaping has been implemented for `Scorched::Request#unmatched_path`. This modification directly affects route matching. Previously, routes were matched against the escaped path, e.g. `/this%20has%20spaces`. Routes are now matched against the unescaped form `/this has spaces`. The only exception is the escaped forward-slash `%2F` and percent sign `%25` which remain unaltered for the fact their unescaped form as special meaning which you wouldn't be able to disambiguate. It's however safe to unescape the path a second time to resolve these characters.

### v0.14
* If a matched mapping _passes_ the request and there are no other matching mappings, a 404 status is now set by default, rather than a 200 status.
* Renamed `matched` condition to `handled` to be less ambiguous.

### v0.13
* Added `content_type` condition, corresponding to the `Content-Type` request header.
* Reverted rogue commit containing experimental debugging logging that I didn't plan to merge. Fixes issue #12.

### v0.12
* Halt can now take an optional response body (typically a string).
* Controller now returns a valid rack array, rather than a Scorched::Response.

### v0.11.1
* Fixed an issue where subsequent nested render calls would render the default layout, which they shouldn't (issue #9).
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

