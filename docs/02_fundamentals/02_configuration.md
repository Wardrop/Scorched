Configuration
=============

Scorched includes a few configurable options out of the box. These all have common defaults, or are otherwise left intentionally blank to ensure the developer opts-in to any potentially undesirable or surprising behaviour.

There are two sets of configurables. Those which apply to views, and everything else. Each set of configuration options is a ``Scorched::Options`` instance. This allows configuration options to be inherited and subsequently overriden by child classes. This is handy in many instances, but a common requirement might be to change the view directory or default layout of some sub-controller.

Options
-------

Each configuration is listed below, with the default value of each included.

* ``config[:strip_trailing_slash] = :redirect``  
    Controls how trailing forward slashes in requests are handled.
    * ``:redirect`` - Strips and redirects URL's ending in a forward slash
    * ``:ignore`` - Internally ignores trailing slash
    * ``false`` - Does nothing. Respects the presence of a trailing forward flash.
* ``config[:static_dir] = 'public'``  
    The directory Scorched should serve static files from. Should be set to false if the web server or some other middleware is serving static files.
* ``config[:logger] = Logger.new(STDOUT)`` - Currently does nothing until logging is added to Scorched.

The follow view configuration options can all be overriden when calling ``render``.

* ``view_config[:dir] = 'views'``  
    The directory containing all the view templates, relative to the current working directory.
* ``view_config[:layout] = false``  
    The default layout to use when rendering views. 
* ``view_config[:engine] = :erb``  
    The default rendering engine. This is used when ``render`` is given a filename with no extension, or a string.