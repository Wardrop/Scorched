Milestones
==========

Completed
---------
* Basic request handling and routing
* String and Regex URL matching, with capture support
* Implement route conditions
  * Add HTTP method condition which the route helpers depend on.
* Add route helpers
* Implemented support for sub-controllers
* Implement before and after filters with proper chaining
* Configuration inheritance between controllers - This has been implemented as the Options class.
  * Made Options class dynamic to allow conditions (and possibly more) to be inheritable.
* Mechanism for including Rack middleware.
* Add more route conditions e.g. content-type, language, user-agent, etc.
* Provide means to `halt` request.
  * Add redirect helping for halting and redirecting request
* Mechanism for handling exceptions in routes and before/after filters.
* Add static resource serving. E.g. public folder.

Remaining
---------
Some of these remaining features may be broken out into a separate contrib library to keep the core lean and focused.

* Make filters behave like middleware. Inheritable, but are only executed once. 
* Give them priority support like routes.
* Add specs for each configuration option.
* Implement some form of view rendering, most likely using Tilt.
  * Add view helpers
    * Add helper to easily read and build HTTP query strings. Takes care of "?" and "&" logic, escaping, etc. This is
      intended to make link building easier.
* Provide default error pages
* Environment optimised defaults
  * Production
    * Rack::Protection
  * Development
    * Verbose logging to STDOUT
    
More things will be added to this list as they're thought of and considered.
