require_relative './helper.rb'

module Scorched
  describe Controller do
    let(:generic_handler) do
      proc { |env| [200, {}, ['ok']] }
    end
    
    it "contains a default set of configuration options" do
      app.config.should be_a(Options)
      app.config.length.should > 0
    end
    
    it "contains a set of default conditions" do
      app.conditions.should be_a(Options)
      app.conditions.length.should > 0
      app.conditions[:method].should be_a(Proc)
    end
    
    describe "basic route handling" do
      it "gracefully handles 404 errors" do
        response = rt.get '/'
        response.status.should == 404
      end
    
      it "handles a root rack call correctly" do
        app << {pattern: '/$', target: generic_handler}
        response = rt.get '/'
        response.status.should == 200
      end
    
      it "does not maintain state between requests" do
        app << {pattern: '/state', target: proc { |env| [200, {}, [@state = 1 + @state.to_i]] }}
        response = rt.get '/state'
        response.body.should == '1'
        response = rt.get '/state'
        response.body.should == '1'
      end
      
      it "raises exception when invalid mapping hash given" do
        expect {
          app << {pattern: '/'}
        }.to raise_error(ArgumentError)
        expect {
          app << {target: generic_handler}
        }.to raise_error(ArgumentError)
      end
    end
    
    describe "URL matching" do
      it 'always matches from the beginning of the URL' do
        app << {pattern: 'about', target: generic_handler}
        response = rt.get '/about'
        response.status.should == 404
      end
      
      it "matches eagerly by default" do
        req = nil
        app << {pattern: '/*', target: proc do |env|
          req = request; [200, {}, ['ok']]
        end}
        response = rt.get '/about'
        req.captures.should == ['about']
      end
      
      it "can be forced to match end of URL" do
        app << {pattern: '/about$', target: generic_handler}
        response = rt.get '/about/us'
        response.status.should == 404
        app << {pattern: '/about', target: generic_handler}
        response = rt.get '/about/us'
        response.status.should == 200
      end
      
      it "unescapes all characters except for the forward-slash and percent sign" do
        app << {pattern: '/a (quite) big fish', target: generic_handler}
        rt.get('/a%20%28quite%29%20big%20fish').status.should == 200
        app << {pattern: '/article/100%25 big%2Fsmall', target: generic_handler}
        rt.get('/article/100%25%20big%2Fsmall').status.should == 200
        app << {pattern: '/*$', target: generic_handler}
        rt.get('/page%2Fabout').status.should == 200
        rt.get('/page/about').status.should == 404
      end
      
      it "unmatched path doesn't always begin with a forward slash" do
        gh = generic_handler
        app << {pattern: '/ab', target: Class.new(Scorched::Controller) do
          map(pattern: 'out', target: gh)
        end}
        resp = rt.get('/about')
        resp.status.should == 200
        resp.body.should == "ok"
      end
      
      it "unmatched path begins with forward slash if last match was up to or included a forward slash" do
        gh = generic_handler
        app << {pattern: '/about/', target: Class.new(Scorched::Controller) do
          map(pattern: '/us', target: gh)
        end}
        app << {pattern: '/contact', target: Class.new(Scorched::Controller) do
          map(pattern: '/us', target: gh)
        end}
        rt.get('/about/us').body.should == "ok"
        rt.get('/contact/us').body.should == "ok"
      end
      
      it "can match anonymous wildcards" do
        req = nil
        app << {pattern: '/anon/*/**', target: proc do |env|
          req = request; [200, {}, ['ok']]
        end}
        response = rt.get '/anon/jeff/has/crabs'
        req.captures.should == ['jeff', 'has/crabs']
      end
      
      it "can match named wildcards (ignoring anonymous captures)" do
        req = nil
        app << {pattern: '/anon/:name/*/::infliction', target: proc do |env|
          req = request; [200, {}, ['ok']]
        end}
        response = rt.get '/anon/jeff/smith/has/crabs'
        req.captures.should == {name: 'jeff', infliction: 'has/crabs'}
      end
      
      example "wildcards match one or more characters" do
        app << {pattern: '/*', target: proc { |env| [200, {}, ['ok']] }}
        rt.get('/').status.should == 404
        rt.get('/dog').status.should == 200
        app.mappings.clear
        app << {pattern: '/**', target: proc { |env| [200, {}, ['ok']] }}
        rt.get('/').status.should == 404
        rt.get('/dog/cat').status.should == 200
        app.mappings.clear
        app << {pattern: '/:page', target: proc { |env| [200, {}, ['ok']] }}
        rt.get('/').status.should == 404
        rt.get('/dog').status.should == 200
        app.mappings.clear
        app << {pattern: '/::page', target: proc { |env| [200, {}, ['ok']] }}
        rt.get('/').status.should == 404
        rt.get('/dog/cat').status.should == 200
      end
      
      example "wildcards can optionally match zero or more characters" do
        app << {pattern: '/*?', target: proc { |env| [200, {}, ['ok']] }}
        rt.get('/').status.should == 200
        rt.get('/dog').status.should == 200
        app.mappings.clear
        app << {pattern: '/**?', target: proc { |env| [200, {}, ['ok']] }}
        rt.get('/').status.should == 200
        rt.get('/dog/cat').status.should == 200
        app.mappings.clear
        app << {pattern: '/:page?', target: proc { |env| [200, {}, ['ok']] }}
        rt.get('/').status.should == 200
        rt.get('/dog').status.should == 200
        app.mappings.clear
        app << {pattern: '/::page?', target: proc { |env| [200, {}, ['ok']] }}
        rt.get('/').status.should == 200
        rt.get('/dog/cat').status.should == 200
      end
      
      it "can match regex and preserve anonymous captures" do
        req = nil
        app << {pattern: %r{/anon/([^/]+)/(.+)}, target: proc do |env|
          req = request; [200, {}, ['ok']]
        end}
        response = rt.get '/anon/jeff/has/crabs'
        req.captures.should == ['jeff', 'has/crabs']
      end
      
      it "can match regex and preserve named captures (ignoring anonymous captures)" do
        req = nil
        app << {pattern: %r{/anon/(?<name>[^/]+)/([^/]+)/(?<infliction>.+)}, target: proc do |env|
          req = request; [200, {}, ['ok']]
        end}
        response = rt.get '/anon/jeff/smith/has/crabs'
        req.captures.should == {name: 'jeff', infliction: 'has/crabs'}
      end
      
      it "matches routes based on priority, otherwise giving precedence to those defined first" do
        order = []
        app << {pattern: '/', priority: -1, target: proc { |env| order << 'four'; [200, {}, ['ok']] }}
        app << {pattern: '/', target: proc { |env| order << 'two'; throw :pass }}
        app << {pattern: '/', target: proc { |env| order << 'three'; throw :pass }}
        app << {pattern: '/', priority: 2, target: proc { |env| order << 'one'; throw :pass }}
        rt.get('/').body.should == 'ok'
        order.should == %w{one two three four}
      end
      
      it "finds the best match for media type whilst respecting priority and definition order" do
        app << {pattern: '/', conditions: {media_type: 'text/html'}, target: proc { |env|
          [200, {}, ['text/html']]
        }}
        app << {pattern: '/', conditions: {media_type: 'application/json'}, target: proc { |env|
          [200, {}, ['application/json']]
        }}
        app << {pattern: '/', priority: 1, target: proc { |env|
          [200, {}, ['anything']]
        }}
        rt.get('/', media_type: 'application/json, */*;q=0.5').body.should == 'anything'
        app.mappings.pop
        rt.get('/', {}, 'HTTP_ACCEPT' => 'text/html;q=0.5, application/json').body.should == 'application/json'
        rt.get('/', {}, 'HTTP_ACCEPT' =>  'text/html, */*;q=0.5').body.should == 'text/html'
      end
    end
    
    describe "conditions" do
      it "contains a default set of conditions" do
        app.conditions.should be_a(Options)
        app.conditions.should include(:method, :media_type)
        app.conditions.each { |k,v| v.should be_a(Proc) }
      end
      
      it "executes route only if all conditions return true" do
        app << {pattern: '/$', conditions: {method: 'POST'}, target: generic_handler}
        response = rt.get "/"
        response.status.should be_between(400, 499)
        response = rt.post "/"
        response.status.should == 200
        
        app.conditions[:has_name] = proc { |name| request.GET['name'] }
        app << {pattern: '/about', conditions: {method: ['GET', 'POST'], has_name: 'Ronald'}, target: generic_handler}
        response = rt.get "/about"
        response.status.should be_between(400, 499)
        response = rt.get "/about", name: 'Ronald'
        response.status.should == 200
      end
      
      it "raises exception when condition doesn't exist or is invalid" do
        app << {pattern: '/', conditions: {surprise_christmas_turkey: true}, target: generic_handler}
        expect {
          rt.get "/"
        }.to raise_error(Scorched::Error)
      end
      
      it "falls through to next route when conditions are not met" do
        app << {pattern: '/', conditions: {method: 'POST'}, target: proc { |env| [200, {}, ['post']] }}
        app << {pattern: '/', conditions: {method: 'GET'}, target: proc { |env| [200, {}, ['get']] }}
        rt.get("/").body.should == 'get'
        rt.post("/").body.should == 'post'
      end
      
      it "inverts the conditions if it's referenced with a trailing exclamation mark" do
        app << {pattern: '/', conditions: {method!: 'GET'}, target: proc { |env| [200, {}, ['ok']] }}
        rt.get("/").status.should == 405
        rt.post("/").status.should == 200
      end
    end
    
    describe "route helpers" do
      it "allows end points to be defined more succinctly" do
        route_proc = app.route('/*', 2, method: 'GET') { |capture| capture }
        mapping = app.mappings.first
        mapping.should == {pattern: mapping[:pattern], priority: 2, conditions: {method: 'GET'}, target: route_proc}
        rt.get('/about').body.should == 'about'
      end
      
      it "can provide a mapping proc without mapping it" do
        block = proc { |capture| capture }
        wrapped_block = app.route(&block)
        app.mappings.length.should == 0
        block.should_not == wrapped_block
        app << {pattern: '/*', target: wrapped_block}
        rt.get('/turkey').body.should == 'turkey'
      end
      
      it "provides a method for every HTTP method" do
        [:get, :post, :put, :delete, :options, :head, :patch].each do |m|
          app.send(m, '/say_cool') { 'cool' }
          rt.send(m, '/say_cool').body.should == (m == :head ? '' : 'cool')
        end
      end
      
      it "provides wildcard captures as arguments" do
        app.get('/*/**') { |a,b| "#{a} #{b}" }
        rt.get('/hello/there/dude').body.should == 'hello there/dude'
      end
      
      it "provides named captures as individual arguments for each value" do
        app.get('/:given_name') { |a| a }
        app.get('/:given_name/::surname') { |a,b| "#{a} #{b}" }
        rt.get('/bob').body.should == 'bob'
        rt.get('/bob/smith').body.should == 'bob smith'
      end
      
      it "always matches to the end of the URL (implied $)" do
        app.get('/') { 'awesome '}
        rt.get('/dog').status.should == 404
        rt.get('/').status.should == 200
      end
      
      it "leaves body empty if nil is returned" do
        app.get('/') { }
        app.after do
          response.body.should == []
        end
        rt.get('/')
      end
      
      it "can take an array of patterns" do
        app.get(['/', '/dog']) { 'rad' }
        rt.get('/dog').status.should == 200
        rt.get('/').status.should == 200
        rt.get('/cat').status.should == 404
      end
    end
    
    describe "sub-controllers" do
      it "should ignore the already matched portions of the path" do
        app << {pattern: '/article', target: Class.new(Scorched::Controller) do
          get('/*') { |title| title }
        end}
        rt.get('/article/hello-world').body.should == 'hello-world'
      end

      it "copies env, modifying PATH_INFO and SCRIPT_NAME, before passing onto Rack-callable object" do
        inner_env, outer_env = nil, nil
        app.before { outer_env = env }
        app.controller '/article' do
          get '/name' do
            inner_env = env
            'hello'
          end
        end
        
        resp = rt.get('/article/name')
        resp.status.should == 200
        outer_env['SCRIPT_NAME'].should == ''
        outer_env['PATH_INFO'].should == '/article/name'
        inner_env['SCRIPT_NAME'].should == '/article'
        inner_env['PATH_INFO'].should == '/name'
      end
      
      example "PATH_INFO and SCRIPT_NAME joined, should produce a full path" do
        app.controller '/article/' do
          get '/name' do
            env['SCRIPT_NAME'] + env['PATH_INFO']
          end
        end
        app.controller '/blah' do
          get '/baz' do
            env['SCRIPT_NAME'] + env['PATH_INFO']
          end
        end
        rt.get('/article/name').body.should == '/article/name'
        rt.get('/blah/baz').body.should == '/blah/baz'
      end

      describe "controller helper" do
        it "can be given no arguments" do
          app.controller do
            get('/') { 'hello' }
          end
          response = rt.get('/')
          response.status.should == 200
          response.body.should == 'hello'
        end
      
        it "can be given a pattern" do
          app.controller '/dog' do
            get('/') { 'roof' }
          end
          response = rt.get('/dog')
          response.status.should == 200
          response.body.should == 'roof'
        end
      
        it "inherits from parent class, or otherwise the specified class" do
          app.controller{}.superclass.should == app
          app.controller('/', String){}.superclass.should == String
        end
      
        it "can take mapping options" do
          app.controller priority: -1, conditions: {method: 'POST'} do
            route('/') { 'ok' }
          end
          app.mappings.first[:priority].should == -1
          rt.get('/').status.should be_between(400, 499)
          rt.post('/').body.should == 'ok'
        end
        
        it "automatically passes to the outer controller when no match" do
          filters_run = 0
          app.controller do
            before { filters_run += 1 }
            get('/sub') { 'goodbye' }
            after { filters_run += 1 }
          end
          app.get('/') { 'hello' }
          rt.get('/').body.should == 'hello'
          filters_run.should == 0
        end
        
        it "can be used to map a predefined controller" do
          person_controller = Class.new(Scorched::Controller) do
            get('/name') { 'George' }
          end
          app.controller '/person', person_controller
          rt.get('/person/name').body.should == 'George'
        end
      end
    end
    
    describe "before/after filters" do
      they "run directly before and after the target action" do
        order = []
        app.get('/') { order << :action }
        app.after { order << :after }
        app.before { order << :before }
        rt.get('/')
        order.should == [:before, :action, :after]
      end
      
      they "run in the context of the controller (same as the route)" do
        route_instance = nil
        before_instance = nil
        after_instance = nil
        app.get('/') { route_instance = self }
        app.before { before_instance = self }
        app.after { after_instance = self }
        rt.get('/')
        route_instance.should == before_instance
        route_instance.should == after_instance
      end
      
      they "should run even if no route matches" do
        counter = 0
        app.before { counter += 1 }
        app.after { counter += 1 }
        rt.delete('/').status.should == 404
        counter.should == 2
      end
      
      they "can take an optional set of conditions" do
        counter = 0
        app.before(method: ['GET', 'PUT']) { counter += 1  }
        app.after(method: ['GET', 'PUT']) { counter += 1  }
        rt.post('/')
        rt.get('/')
        rt.put('/')
        counter.should == 4
      end
      
      they "execute in the order they're defined" do
        order = []
        app.before { order << :first }
        app.before { order << :second }
        app.after { order << :third }
        app.after { order << :fourth }
        rt.get('/')
        order.should == %i{first second third fourth}
      end
      
      describe "nesting" do
        example "filters inherit but only run once" do
          before_counter, after_counter = 0, 0
          app.before { before_counter += 1  }
          app.after { after_counter += 1  }
          subcontroller = app.controller { get('/') { 'wow' } }
          subcontroller.filters[:before].should == app.filters[:before]
          subcontroller.filters[:after].should == app.filters[:after]
          
          rt.get('/')
          before_counter.should == 1
          after_counter.should == 1
          
          # Hitting the subcontroller directly should yield the same results.
          before_counter, after_counter = 0, 0
          Rack::Test::Session.new(subcontroller).get('/')
          before_counter.should == 1
          after_counter.should == 1
        end
        
        example "before filters run from outermost to innermost" do
          order = []
          app.before { order << :outer }
          app.before { order << :outer2 }
          app.controller do
            before { order << :inner }
            before { order << :inner2 }
            get('/') { }
          end
          rt.get('/')
          order.should == %i{outer outer2 inner inner2}
        end
        
        example "after filters run from innermost to outermost" do
          order = []
          app.after { order << :outer }
          app.after { order << :outer2 }
          app.controller do
            get('/') { }
            after { order << :inner }
            after { order << :inner2 }
          end
          rt.get('/')
          order.should == %i{inner inner2 outer outer2}
        end
        
        example "inherited filters which fail to satisfy their conditions are re-evaluated at every level" do
          order = []
          sub_class = app.controller do
            def initialize(env)
              super(env)
              response.status = 500
            end
            before { order << :third }
            get('/hello') { }
          end
          app.before(status: 500) do
            order << :second
            self.class.should == sub_class
          end
          app.before do
            order << :first
          end
          rt.get('/hello')
          order.should == %i{first second third}
        end
      end
    end
    
    describe "error filters" do
      let(:app) do
        Class.new(Scorched::Controller) do
          route '/' do
            raise StandardError
          end
        end
      end
      
      they "catch exceptions" do
        app.error { response.status = 500 }
        rt.get('/').status.should == 500
      end
      
      they "receive the exception object as their first argument" do
        error = nil
        app.error { |e| error = e }
        rt.get('/')
        error.should be_a(StandardError)
      end
      
      they "try the next handler if the previous handler returns false" do
        handlers_called = 0
        app.error { handlers_called += 1 }
        app.error { handlers_called += 1 }
        rt.get '/'
        handlers_called.should == 1
        
        app.error_filters.clear
        handlers_called = 0
        app.error { handlers_called += 1; false }
        app.error { handlers_called += 1 }
        rt.get '/'
        handlers_called.should == 2
      end
      
      they "still runs after filters if route error is handled" do
        app.after { response.status = 111 }
        app.error { true }
        rt.get('/').status.should == 111
      end
      
      they "can handle exceptions in before/after filters" do
        app.error { |e| response.write e.class.name }
        app.after { raise ArgumentError }
        rt.get('/').body.should == 'StandardErrorArgumentError'
      end
      
      they "swallow halts when executed in an outer context" do
        app.before { raise "Big bad error" }
        app.error { throw :halt }
        rt.get('/') # Would otherwise bomb out with uncaught throw.
      end
      
      they "only get called once per error" do
        times_called = 0
        app.error { times_called += 1 }
        rt.get '/'
        times_called.should == 1
      end
      
      they "fall through when unhandled" do
        expect {
          rt.get '/'
        }.to raise_error(StandardError)
      end
      
      they "can optionally filter on one or more exception types" do
        app.get('/arg_error') { raise ArgumentError }
        
        app.error(StandardError, ArgumentError) { true }
        rt.get '/'
        rt.get '/arg_error'
        
        app.error_filters.clear
        app.error(ArgumentError) { true }
        expect {
          rt.get '/'
        }.to raise_error(StandardError)
        rt.get '/arg_error'
      end
      
      they "can take an optional set of conditions" do
        app.error(method: ['GET', 'PUT']) { true  }
        expect {
          rt.post('/')
        }.to raise_error(StandardError)
        rt.get('/')
        rt.put('/')
      end
    end
    
    describe "middleware" do
      let(:app) do
        Class.new(Scorched::Controller) do
          self.middleware << proc { use Scorched::SimpleCounter }
          get '/'do
            request.env['scorched.simple_counter']
          end
          controller '/sub_controller' do
            get '/' do
              request.env['scorched.simple_counter']
            end
          end
        end
      end
      
      it "is only included once by default" do
        rt.get('/').body.should == '1'
        rt.get('/sub_controller').body.should == '1'
      end
      
      it "can be explicitly included more than once in sub-controllers" do
        app.mappings[-1][:target].middleware << proc { use Scorched::SimpleCounter }
        rt.get('/').body.should == '1'
        rt.get('/sub_controller').body.should == '2'
      end
    end
    
    describe "halting" do
      it "short circuits current request" do
        has_run = false
        app.get('/') { halt; has_run = true }
        rt.get '/'
        has_run.should be_false
      end
      
      it "takes an optional status" do
        app.get('/') { halt 600 }
        rt.get('/').status.should == 600
      end
      
      it "takes an optional response body" do
        app.get('/') { halt 'cool' }
        rt.get('/').body.should == 'cool'
      end
      
      it "can take a status and a response body" do
        app.get('/') { halt 600, 'cool' }
        rt.get('/').status.should == 600
        rt.get('/').body.should == 'cool'
      end
      
      it "still processes filters" do
        app.after { response.status = 600 }
        app.get('/') { halt }
        rt.get('/').status.should == 600
      end
      
      describe "within filters" do
        it "short circuits filters if halted within filter" do
          app.before { halt }
          app.after { response.status = 600 }
          rt.get('/').status.should_not == 600
        end
        
        it "forced filters are always run" do
          app.before { halt }
          app.after(force: true) { response.status = 600 }
          app.after { response.status = 700 } # Shouldn't run because it's not forced
          app.get('/') { 'hello' }
          rt.get('/').status.should == 600
        end
        
        it "halting within a forced filter still runs other forced filters" do
          app.before { halt }
          app.before(force: true) { halt }
          app.before(force: true) { response.status = 600 }
          app.get('/') { 'hello' }
          rt.get('/').status.should == 600
          app.after(force: true) { response.status = 700 }
          rt.get('/').status.should == 700
        end
      end
    end
    
    describe 'redirecting' do
      it "redirects using 303 or 302 by default, depending on HTTP version" do
        app.get('/cat') { redirect '/dog' }
        response = rt.get('/cat', {}, 'HTTP_VERSION' => 'HTTP/1.1')
        response.status.should == 303
        response.location.should == '/dog'
        response = rt.get('/cat', {}, 'HTTP_VERSION' => 'HTTP/1.0')
        response.status.should == 302
        response.location.should == '/dog'
      end
      
      it "allows the HTTP status to be overridden" do
        app.get('/') { redirect '/somewhere', 308 }
        rt.get('/').status.should == 308
      end
      
      it "halts the request after redirect" do
        var = false
        app.get('/') do
          redirect '/somewhere'
          var = true
        end
        rt.get('/')
        var.should == false
      end
      
      it "works in filters" do
        app.error { redirect '/somewhere' }
        app.get('/') { raise "Some error" }
        rt.get('/').location.should == '/somewhere'
        app.before { redirect '/somewhere_else' }
        rt.get('/').location.should == '/somewhere_else'
      end
    end
    
    describe "passing" do
      it "invokes the next match" do
        app.get('/') { response.body << 'hello'; pass }
        app.get('/') { response.body << ' there'; pass }
        app.get('/') { response.body << ' sir' }
        app.get('/') { response.body << '!' } # Shouldn't be hit
        rt.get('/').body.should == 'hello there sir'
      end
      
      it "invokes the next match in parent controller if passed from filter" do
        effects = []
        app.controller '/sub' do
          get('/') { }
          after do
            effects.push 1
            response.body << 'x'
            pass
          end
        end
        app.get('/sub') {
          effects.push 2
          response.body << 'y'
        }
        rt.get('/sub').body.should == 'y'
        effects.should == [1, 2]
      end
      
      it "results in uncaught symbol if passing within filter of root controller " do
        app.before { pass }
        expect {
          app.get('/') { }
          rt.get('/')
        }.to raise_error(ArgumentError)
      end
      
      it "is not considered a match if a mapping passes the request" do
        app.get('/*') { pass }
        app.get('/nopass') {  }
        handled = nil
        app.after { handled = @_handled }
        rt.get('/').status.should == 404 # 404 if matched, but passed
        handled.should_not be_true
        rt.get('/nopass').status.should == 200
        handled.should be_true
      end
    end
    
    describe "status codes" do
      it "returns 405 when :method condition fails" do
        app.get('/') { }
        rt.post('/').status.should == 405
      end
      
      it "returns 404 when :host condition fails" do
        app.get('/', host: 'somehost') { }
        rt.get('/').status.should == 404
      end
      
      it "returns 406 when accept-related conditions fail" do
        app.get('/media_type', media_type: 'application/json') { }
        app.get('/charset', charset: 'iso-8859-5') { }
        app.get('/encoding', encoding: 'gzip') { }
        app.get('/language', language: 'en') { }
        
        rt.get('/media_type', {}, 'HTTP_ACCEPT' => 'application/json').status.should == 200
        rt.get('/media_type', {}, 'HTTP_ACCEPT' => 'text/html').status.should == 406
        rt.get('/charset', {}, 'HTTP_ACCEPT_CHARSET' => 'iso-8859-5').status.should == 200
        rt.get('/charset', {}, 'HTTP_ACCEPT_CHARSET' => 'iso-8859-5;q=0').status.should == 406
        rt.get('/encoding', {}, 'HTTP_ACCEPT_ENCODING' => 'gzip').status.should == 200
        rt.get('/encoding', {}, 'HTTP_ACCEPT_ENCODING' => 'compress').status.should == 406
        rt.get('/language', {}, 'HTTP_ACCEPT_LANGUAGE' => 'en').status.should == 200
        rt.get('/language', {}, 'HTTP_ACCEPT_LANGUAGE' => 'da').status.should == 406
      end
    end
    
    describe "configuration" do
      describe :strip_trailing_slash do
        it "can be set to strip trailing slash and redirect" do
          app.config[:strip_trailing_slash] = :redirect
          app.get('/test') { }
          response = rt.get('/test/')
          response.status.should == 307
          response['Location'].should == '/test'
        end
        
        it "can be set to ignore trailing slash while pattern matching" do
          app.config[:strip_trailing_slash] = :ignore
          hit = false
          app.get('/test') { hit = true }
          rt.get('/test/').status.should == 200
          hit.should == true
        end
        
        it "can be set not do nothing with a trailing slash" do
          app.config[:strip_trailing_slash] = false
          app.get('/test') { }
          rt.get('/test/').status.should == 404
          
          app.get('/test/') { }
          rt.get('/test/').status.should == 200
        end
      end
      
      describe :static_dir do
        it "can serve static file from the specific directory" do
          app.config[:static_dir] = 'public'
          response = rt.get('/static.txt')
          response.status.should == 200
          response.body.should == 'My static file!'
        end
        
        it "can be disabled" do
          app.config[:static_dir] = false
          response = rt.get('/static.txt')
          response.status.should == 404
        end
      end
      
      describe :show_exceptions do
        it "shows debug-friendly error page for unhandled exceptions" do
          app.config[:show_exceptions] = true
          app.get('/') { raise RuntimeError, "Kablamo!" }
          response = rt.get('/')
          response.status.should == 500
          response.body.should include('Rack::ShowExceptions')
        end
        
        it "can be disabled" do
          app.config[:show_exceptions] = false
          app.get('/') { raise RuntimeError, "Kablamo!" }
          expect {
            response = rt.get('/')
          }.to raise_error(RuntimeError)
        end
      end
      
      describe :show_http_error_pages do
        it "shows HTTP error pages for errors 400 to 599" do
          app.config[:show_http_error_pages] = true
          app.get('/') { response.status = 501; '' }
          app.get('/unknown') { response.status = 480; nil }
          rt.get('/').body.should include('501 Not Implemented')
          rt.post('/').body.should include('405 Method Not Allowed')
          rt.get('/unknown').body.should include('480 ')
        end
        
        it "can be disabled" do
          app.config[:show_http_error_pages] = false
          app.get('/') { response.status = 501; '' }
          app.get('/unknown') { response.status = 480; nil }
          rt.get('/').body.should_not include('501 Not Implemented')
          rt.post('/').body.should_not include('405 Method Not Allowed')
          rt.post('/unknown').body.should_not include('408 ')
        end
      end
      
      describe :auto_pass do
        it "passes to the outer controller without running any filters, if no match" do
          sub = Class.new(Scorched::Controller) do
            config[:auto_pass] = true
            before { response.status = 600 }
            get('/hello') { 'hello' }
            after { response.status = 600 }
          end
          app << {pattern: '/', target: sub}
          app.get('/') { 'ok' }
          rt.get('/').body.should == 'ok'
          rt.get('/').status.should == 200
          rt.get('/hello').body.should == 'hello'
          rt.get('/hello').status.should == 600
          
          sub.config[:auto_pass] = false
          rt.get('/').body.should == ''
          rt.get('/').status.should == 600
        end
      end
      
      describe :cache_templates do
        before(:each) do
          File.open('views/temp.str', 'w') { |f| f.write 'hello world' }
        end
        
        after(:all) {
          File.unlink 'views/temp.str'
        }
        
        it "can cache templates" do
          app.config[:cache_templates] = true
          app.get('/') { render :'temp.str' }
          rt.get('/').body.should == 'hello world'
          File.open('views/temp.str', 'a') { |f| f.write '!!!' }
          rt.get('/').body.should == 'hello world'
        end
        
        it "can be set not to cache templates" do
          app.config[:cache_templates] = false
          app.get('/') { render :'temp.str' }
          rt.get('/').body.should == 'hello world'
          File.open('views/temp.str', 'a') { |f| f.write '!!!' }
          rt.get('/').body.should == 'hello world!!!'
        end
      end
    end
    
    describe "sessions" do
      it "provides convenience method for accessing the Rack session" do
        rack_session = nil
        app.get('/') { rack_session = session }
        rt.get('/')
        rack_session.should be_nil
        app.middleware << proc { use Rack::Session::Cookie, secret: 'test' }
        rt.get('/')
        rack_session.should be_a(Rack::Session::Abstract::SessionHash)
      end
      
      describe "flash" do
        before(:each) do
          app.middleware << proc { use Rack::Session::Cookie, secret: 'test' }
        end
        
        it "keeps session variables that live for one page load" do
          app.get('/set') { flash[:cat] = 'meow' }
          app.get('/get') { flash[:cat] }
          
          rt.get('/set')
          rt.get('/get').body.should == 'meow'
          rt.get('/get').body.should == ''
        end
        
        it "always reads from the original request flash" do
          app.get('/') do
            flash[:counter] = flash[:counter] ? flash[:counter] + 1 : 0
            flash[:counter].to_s
          end
          
          rt.get('/').body.should == ''
          rt.get('/').body.should == '0'
          rt.get('/').body.should == '1'
        end
        
        it "can only remove flash variables if the flash object is accessed" do
          app.get('/set') { flash[:cat] = 'meow' }
          app.get('/get') { flash[:cat] }
          app.get('/null') { }
          
          rt.get('/set')
          rt.get('/null')
          rt.get('/get').body.should == 'meow'
          rt.get('/get').body.should == ''
        end
        
        it "can keep multiple sets of flash session variables" do
          app.get('/set_animal') { flash(:animals)[:cat] = 'meow' }
          app.get('/get_animal') { flash(:animals)[:cat] }
          app.get('/set_name') { flash(:names)[:jeff] = 'male' }
          app.get('/get_name') { flash(:names)[:jeff] }
          
          rt.get('/set_animal')
          rt.get('/set_name')
          rt.get('/get_animal').body.should == 'meow'
          rt.get('/get_name').body.should == 'male'
          rt.get('/get_animal').body.should == ''
          rt.get('/get_name').body.should == ''
        end
      end
    end
    
    describe "cookie helper" do
      it "sets, retrieves and deletes cookies" do
        app.get('/') { cookie :test }
        app.post('/') { cookie :test, 'hello' }
        app.post('/goodbye') { cookie :test, {value: 'goodbye', expires: Time.now() + 999999 } }
        app.delete('/') { cookie :test, nil }
        app.delete('/alt') { cookie :test, {value: nil} }
        
        rt.get('/').body.should == ''
        rt.post('/')
        rt.get('/').body.should == 'hello'
        rt.post('/goodbye')
        rt.get('/').body.should == 'goodbye'
        rt.delete('/')
        rt.get('/').body.should == ''
        rt.delete('/alt')
        rt.get('/').body.should == ''
      end
    end
    
    describe "rendering" do
      before(:each) do
        app.render_defaults.each { |k,v| app.render_defaults[k] = nil }
      end

      it "can render a file, relative to the working directory" do
        app.get('/') do
          render(:'views/main.erb').should == "3 for me"
        end
        rt.get('/')
      end

      it "can render a string" do
        app.get('/') do
          render('<%= 1 + 1  %> for you', engine: :erb).should == "2 for you"
        end
        rt.get('/')
      end

      it "takes an optional view directory, relative to the working directory" do
        app.get('/') do
          render(:'main.erb', dir: 'views').should == "3 for me"
        end
        rt.get('/')
      end
      
      it "properly respects absolute and relative file paths in respect to the view directory" do
        app.get('/relative') do
          render(:'../views/main.erb', dir: 'views')
        end
        app.get('/absolute') do
          File.dirname(__FILE__)
          render(:"#{File.dirname(__FILE__)}/views/main.erb", dir: 'views')
        end
        rt.get('/relative').body.should == "3 for me"
        rt.get('/absolute').body.should == "3 for me"
      end

      it "takes an optional block to be yielded by the view" do
        app.get('/') do
          render(:'views/layout.erb'){ "in the middle" }.should == "(in the middle)"
        end
        rt.get('/')
      end

      it "renders the given layout" do
        app.get('/') do
          render(:'views/main.erb', layout: :'views/layout.erb').should == "(3 for me)"
        end
        rt.get('/')
      end

      it "merges options with view config" do
        app.get('/') do
          render(:'main.erb').should == "3 for me"
        end
        app.get('/full_path') do
          render(:'views/main.erb', {layout: :'views/layout.erb', dir: nil}).should == "(3 for me)"
        end
        app.render_defaults[:dir] = 'views'
        rt.get('/')
        rt.get('/full_path')
      end

      it "derived template engine overrides specified engine" do
        app.render_defaults[:dir] = 'views'
        app.render_defaults[:engine] = :erb
        app.get('/str') do
          render(:'other.str').should == "hello hello"
        end
        app.get('/erb_file') do
          render(:main).should == "3 for me"
        end
        app.get('/erb_string') do
          render('<%= 1 + 1  %> for you').should == "2 for you"
        end
        rt.get('/str')
        rt.get('/erb_file')
        rt.get('/erb_string')
      end

      it "ignores default layout when called within a view" do
        app.render_defaults << {:dir => 'views', :layout => :layout, :engine => :erb}
        app.get('/') do
          render :composer
        end
        rt.get('/').body.should == '({1 for none}{1 for none})'
      end
      
      it "can pass local variables through to view" do
        app.get '/' do
          render '<%= var %>', engine: 'erb', dir: 'views', locals: {var: 'hello sailor'}
        end
        rt.get('/').body.should == 'hello sailor'
      end
      
      it "provides a means for passing options directly to tilt" do
        Tilt.register(Class.new(Tilt::ERBTemplate) do
          def prepare
            options[:engine].new if options[:engine]
            super
          end
        end, 'test')
        
        app.get '/safe' do
          render '<%= var %>', engine: 'test', dir: 'views', locals: {var: 'hello sailor'}
          render '<%= var %>', engine: 'test', dir: 'views', locals: {var: 'hello sailor'}, tilt: {engine: Class.new}
        end
        rt.get('/safe').body.should == 'hello sailor'
        
        app.get '/boomer' do
          render '<%= var %>', engine: 'test', dir: 'views', locals: {var: 'hello sailor'}, tilt: {engine: 'invalid'}
        end
        expect {
          rt.get('/boomer')
        }.to raise_error(NoMethodError)
      end
    end
    
    describe "url helpers" do
      let(:my_app) do
        Class.new(Scorched::Controller)
      end
      
      let(:root_app) do
        Class.new(Scorched::Controller)
      end

      let(:app) do
        this = self
        builder = Rack::Builder.new
        builder.map('/myapp') { run this.my_app }
        builder.map('/') { run this.root_app }
        builder.to_app
      end
      
      it "can determine the root path of the current Scorched application" do
        my_app.controller '/article' do
          get '/name' do
            env['scorched.root_path']
          end
        end
        rt.get('/myapp/article/name').body.should == '/myapp'
      end
      
      describe "url" do
        it "returns the fully qualified URL" do
          my_app.get('/') { url }
          rt.get('https://scorchedrb.com:73/myapp?something=true').body.should ==
            'https://scorchedrb.com:73/myapp'
        end
        
        it "can append an optional path" do
          my_app.get('/') { url('hello') }
          rt.get('https://scorchedrb.com:73/myapp?something=true').body.should ==
            'https://scorchedrb.com:73/myapp/hello'
        end
        
        it "returns the given URL if scheme detected" do
          test_url = 'http://google.com/blah'
          my_app.get('/') { url(test_url) }
          rt.get('/myapp').body.should == test_url
        end
        
        it "generates URL from inside subcontroller defined with controller helper" do
          root_app.controller '/sub2' do
            get('/') { url('hi') }
          end
          rt.get('https://scorchedrb.com:73/sub2').body.should == 'https://scorchedrb.com:73/hi'
        end
      end
      
      describe "absolute" do
        it "returns an absolute URL path" do
          my_app.get('/absolute') { absolute }
          rt.get('http://scorchedrb.com/myapp/absolute?something=true').body.should == '/myapp'
        end
        
        it "returns a forward slash if script name is the root of the URL path" do
          root_app.get('/') { absolute }
          rt.get('http://scorchedrb.com').body.should == '/'
        end
        
        it "can append an optional path" do
          my_app.get('/absolute') { absolute('hello') }
          rt.get('http://scorchedrb.com/myapp/absolute?something=true').body.should == '/myapp/hello'
        end
        
        it "returns the given URL if scheme detected" do
          test_url = 'http://google.com/blah'
          my_app.get('/') { absolute(test_url) }
          rt.get('/myapp').body.should == test_url
        end
        
        it "returns an absolute URL path for subcontroller defined with controller helper" do
          root_app.controller '/sub2' do
            get('/') { absolute }
          end
          rt.get('https://scorchedrb.com:73/sub2').body.should == '/'
        end
      end
    end
    
    describe "delegators" do
      it "delegates captures" do
        app.get('/:id') { captures[:id] }
        rt.get('/587').body.should == '587'
      end
    end

  end
end
