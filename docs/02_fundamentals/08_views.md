Views
=====

Scorched uses Tilt to render templates in various supported formats. Because of this, views have been implemented as a single method, ``render``.

``render`` can take a file path or a string as the template. If a symbol is given, it assumes it's a file path, were as a string is assumed to be the template markup. ``render`` can also takes a set of options.

* ``:dir`` - The directory containing the views. This can be absolute or relative to the current working directory.
* ``:layout`` - The template to render _around_ the view. This results in a subsequent call to ``render``, where this value is sent as the first argument. Layout's inherit the settings of the main template being rendered.
* ``:engine`` - The template engine to use if it can't be derived from the file name. This is always required for string templates. Can be any string or symbol that Tilt recognises, e.g :erb, :haml, :sass, etc.

Any unrecognised options are passed through to Tilt and the corresponding rendering engine.

Finally, ``render`` takes an optional block to be _yielded_ within the view being rendered, if supported by the rendering engine.