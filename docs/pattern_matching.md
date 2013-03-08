Patterns
========
All patterns attempt to match the remaining unmatched portion of the request path; the request path being Rack's
`path_info` request variable. The unmatched path will always begin with a forward slash if the previously matched portion of the path ended at a forward slash, regardless of whether it actually included the forward slash in the match, or if the forward slash was the next character. As an example, if the request was to "/article/21", then both "/article/" => "/21" and "/article" => "/21" would match.
    
All patterns must match from the beginning of the path. So even though the pattern "article" would match "/article/21", it wouldn't count as a match because the match didn't start at a non-zero offset.

If a pattern contains named captures, unnamed captures will be lost (this is how named regex captures work in Ruby). So if you name one capture, make sure you name any other captures you may want to access.


String Patterns
---------------
* `*` - Matches all characters excluding the forward slash.
* `**` - Matches all characters including the forward slash.
* `:param` - Same as `*` except the capture is named to whatever the string following the single-colon is.
* `::param` - Same as `**` except the capture is named to whatever the string following the double-colon is.
* `$` - If placed at the end of a pattern, the pattern only matches if it matches the entire path. For patterns defined using the route helpers, e.g. ``Controller.route``, ``Controller.get``, this is implied. 


Regex Patterns
--------------
Regex patterns offer more power and flexibility than string patterns (naturally). The rules for Regex patterns are identical to String patterns, e.g. they must match from the beginning of the path, etc. 
