Request and Session Data
========================

GET and POST Data
-----------------
Many ruby frameworks provide helpers for accessing GET and POST data via some kind of generic accessor, such as a `params` method, but Rack already provides this functionality out of the box, and more.

```ruby
post '/' do
  request.GET['view'] # Key/value pairs submitted in the query string of the URL.
  request.POST['username'] # Key/value pairs submitted in the payload of a POST request.
  request.params[:username] # A merged hash of GET and POST data.
  request[:username] # Shortcut to merged hash of GET and POST data.
end
```

One of the few opinions Scorched does maintain (albeit without imposition), is that GET and POST data should be accessed by their respective methods. GET and POST data are semantically different, so if you're not concerned about where the data came from, it may be a good sign you're doing something wrong.

Uploaded files are also accessible as ordinary fields, except the associated value is a hash of properties, instead of a string. An example of an application that accepts file uploads is included in the "examples" directory of the Scorched git repository.

Cookies
-------
While Rack provides a relatively simple means of setting, retrieving and deleting cookies, Scorched aggregates those three actions into a single method, `cookie`, for the sake of brevity and simplicity.

```ruby
def '/' do
  cookie :previous_page # Retrieves the cookie.
  cookie :previous_page, '/search' # Sets the cookie
  cookie :previous_page, nil # Deletes the cookies
end
```
   
For each of the above lines, the corresponding Rack methods are called, e.g. `Rack::Requeste#cookies`, `Rack::Response#set_cookie` and `Rack::Response#delete_cookie`. The values for setting and deleting a cookie can also be a hash, as per the documentation for `set_cookie` and `delete_cookie`. Deletion is still possible when a Hash is provided, as long as the `value` property is nil.

```ruby
def '/' do
  cookie :view, path: '/account', value: 'datasheet' # Sets the cookie
  cookie :view, path: '/account', value: nil # Deletes the cookie
end
```


Sessions
--------
Sessions are completely handled by Rack. For convenience, Scorched provides a `session` helper. This merely acts as an alias to `request['rack.session']`. It will raise an exception if called without any Rack session middleware loaded, such as `Rack::Session::Cookie`.

```ruby
class App < Scorched::Controller
  middleware << proc {
    use Rack::Session::Cookie, secret: 'blah'
  }
  
  get '/' do
    session['logged_in'] ? 'You're currently logged in.' : 'Please login.'
  end
end
```

###Flash Session Data
A common requirement for websites, especially web applications, is to provide a message on the next page load corresponding to an action that a user has just performed. A common framework idiom that Scorched happily implements are flash session variables - special session data that lives for only a single page load.

This isn't as trivial to implement as it may sound at a glance, which is why Scorched provides this helper out-of-the-box.

```ruby
get '/' do
  "<span class="success">#{flash[:success]}</span>" if flash[:success]
end

post '/login' do
  flash[:success] = 'Logged in successfully.'
end
```

The flash helper allows multiple sets of flash session data to be stored under different names. Because of how flash sessions are implemented, they're only deleted on the next page load if that particular flash data set is accessed. These properties of flash sessions can satisfy some interesting use cases. Here's a very uninteresting example:

```ruby
class App < Scorched::Controller
  get '/' do
    "<span class="success">#{flash[:success]}</span>" if flash[:success]
  end

  post '/login' do
    flash[:success] = 'Logged in successfully.'
    if user.membership_type == 'vip' && user.membership_expiry < 5
      flash(:vip)[:warning] = 'Your VIP membership is about to expire, please renew it.'
    end
  end
  
  controller '/vip' do
    get '/' do
      "<span class="warning">#{flash(:vip)[:warning]}</span>" if flash(:vip)[:warning]
    end
  end
end
```

In the rather contrived example above, when a VIP user logs in, a message is generated and stored as a flash session variable in the `:vip` flash data set. Because the `:vip` flash data set isn't accessed on the main page, it lives on until it's finally re-accessed on the VIP page.