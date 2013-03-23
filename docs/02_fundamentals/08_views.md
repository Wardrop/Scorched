Views
=====

Scorched uses Tilt to render templates in various supported formats. Because of this, views have been implemented as a single method, `render`.

`render` can take a file path or a string as the template. If a symbol is given, it assumes it's a file path, were as a string is assumed to be the template markup. `render` can also takes a set of options.

* `:dir` - The directory containing the views. This can be absolute or relative to the current working directory.
* `:layout` - The template to render _around_ the view.
* `:engine` - The template engine to use if it can't be derived from the file name. This is always required for string templates. Can be any string or symbol that Tilt recognises, e.g :erb, :haml, :sass, etc.

Any unrecognised options are passed through to Tilt and the corresponding rendering engine. A common example being the `:locals` option, used to set local variables made available within the scope of the view.

Finally, `render` takes an optional block to be _yielded_ within the view being rendered, if supported by the rendering engine. Layout's use this feature.

Layouts
-------
When a layout is given, a subsequent call to `render` is made, with the rendered result of the main template given as the block to be yielded. The defined `:layout` is provided as the first argument on the sub-sequent call to `render`, so the same rules apply. Layouts inherit the options of the main template being rendered.

Partials
--------
There are cases where a you may want a view to be composed of more than just a layout and a single view. The view may contain one or more sub-views, commonly referred to as partials. Scorched makes provisions for this by ignoring the default layout when `render` is called within a view, hence negating the requirement to explicitly override the layout.