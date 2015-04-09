Filters
=======
Filters serve as a handy place to put functionality and behaviour that's common to a set of routes, or for that matter, a whole website or application. Filters are executed in the context of the controller; the same context as routes. Filters are also inheritable, meaning sub-classes inherit the filters of their parent - this inheritance is enabled through the use of the `Scorched::Collection` class, and is implemented such that each filter will only run once per-request.

There are currently two types of filter in Scorched, both of which are documented below.


Before and After Filters
------------------------
Before and After filters allow pre- and post-processing of requests. They are executed before and after each request, respectively.

```ruby
before do
  raise "Must be logged in to access this site" unless session[:logged_in] == true
end
```

Like routes, filters can have conditions defined on them, for example:

```ruby
after media_type: 'application/json' do
  response.body.to_json!
end
```

Before and after filters run even if no route within the controller matches. This makes them suitable for handling 404 errors for example.

```ruby
after status: 404 do
  response.body = render(:not_found)
end
```

An optional _force_ option exists which ensures the filter is always run, even if another filter halts the request.

```ruby
after force: true do
  # Close open file handles or something
end
```

How you use filters is up to your own imagination and creative problem solving.


Error Filters
-------------
Error filters are processed like regular filters, except they're called whenever an exception occurs. If an error filter returns false, it's assumed to be unhandled, and the next error filter is called. This continues until one of the following is true, 1) an error filter returns true, in which case the exception is assumed to be handled, 2) an error filter raises an exception itself, or 3) there are no more error handlers defined on the current controller, in which case the exception is re-raised.

Error filters can handle exceptions raised from within the request target, as well as those raised within _before_ and _after_ filters. The way error filters have been implemented, allows exceptions raised within the request target to be handled before running the _after_ filters. This means that _after_ filters are still run as long as exceptions that occurred within the request target are handled.

Error filters can target only specific types of exception class, in much the same way as a typical Ruby rescue block. In the following example, the error filter is only executed when an uncaught PermissionError exception is raised, and when a made-up `catch_exceptions` condition evaluates to true.

```ruby
error PermissionError, catch_exceptions: true do |e|
  flash[:error] = "You do not have the appropriate permission to perform that action: #{e.message}"
end
```