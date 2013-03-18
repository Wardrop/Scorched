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

You can also configure the default options when rendering views by setting them on the ``render_defaults`` hash. The options specified here are merged with those provided when calling the ``render`` method, with the explicit options obviously taking precedence over the defaults.

Refer to the _views_ page for more information.

Here is an example of the configuration options in action. A couple of different ways to set the options are shown. Refer to the API documentation for the ``Scorched::Options`` for more information.

    # ruby
    class MyApp < Scorched::Controller
      config[:static_dir] = '../public'
      render_defaults.merge!(
        dir: 'templates',
        layout: :main_layout
        engine: :haml
      )
    end