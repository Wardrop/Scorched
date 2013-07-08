Sharing and Managing Request State
==================================
Because Scorched allows sub-controllers to an arbitrary depth and treats all controllers equal (i.e it has no concept of a _root_ controller), it means instance variables and the likes cannot be used to track, maintain or share request state between controllers. I mention this because instance variables are the most common way to manage the request state in frameworks such as Sinatra.

The only data exchanged between controllers is the Rack environment hash. Using the Rack environment hash is the only thread-safe way to manage the request state between controllers. As an example use case, consider the Scorched implementation of flash session data. Flash session data must be shared between controllers throughout the life of the request. The rack environment hash is the only suitable place to store this data.

The Rack idiom is to namespace your keys, typically with your project name, using dots as delimiters. You can further group your keys using more dot-delimited namespaces. Perhaps an example is due:

```ruby
before user_agent: /MSIE|Windows/ do
  env['myapp.dangerous_request'] = true
end

get '/' do
  "Welcome #{env['myapp.user.name']}!"
end
```