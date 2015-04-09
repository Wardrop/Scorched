Views
=====

Scorched uses Tilt to render templates in various supported formats. Thanks of this abstraction, views have been implemented as a single method `render`.

`render` can take a file path or a string as the template. If a symbol is given, it assumes it's a file path, where as a string is assumed to be the template markup. `render` can also take a set of options. These options get their defaults from the `render_defaults` hash, inherited by each sub-controller.

* `:dir` - The directory containing the views. This can be absolute or relative to the current working directory.
* `:layout` - The template to render _around_ the view.
* `:engine` - The template engine to use if it can't be derived from the file name. This is always required for string templates. Can be any string or symbol that Tilt recognises, e.g :erb, :haml, :sass, etc.
* `:locals` - Hash of local variables to be made available in the context of the view.
* `:tilt` - Options to be passed directly to Tilt. Required to avoid conflicts between Scorched options and the options of some renderers.

Any unrecognised options are passed through to Tilt and the corresponding rendering engine. Where such options conflict with those used by Scorched (dependant on the rendering engine), the `:tilt` option provides an unambiguous means to directly pass through those options.

Finally, `render` takes an optional block to be _yielded_ within the view being rendered, if supported by the rendering engine. This feature is used internally as part of the implementation of layouts.

Layouts
-------
When a layout is given, a subsequent call to `render` is made, with the rendered result of the main template given as the block to be yielded. The defined `:layout` is provided as the first argument on the sub-sequent call to `render`, so the same rules apply. Layouts inherit the options of the main template being rendered.

Partials
--------
There are cases where you may want a view to be composed of more than just a layout and a single view. The view may contain one or more sub-views, commonly referred to as partials. Scorched makes provisions for this by ignoring the default layout when `render` is called within a view, hence negating the requirement to explicitly override the layout.

Helpers
-------
No explicit distinction is made between a controller helper and a view helper, as both share the same context. There are however some helper methods intended primarily for views.

* `absolute` - Returns the absolute URL of the web application root, with the optional argument joined to the end. For example, if you're application was mounted under example.com/myapp/: `absolute '/about' #=> /myapp/about`
* `url` - Same as absolute, except returns the full URL, e.g. `url '/about' #=> http://example.com/myapp/about`.