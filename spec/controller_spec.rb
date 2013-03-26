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
      app.conditions[:methods].should be_a(Proc)
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
      
      it "unmatched path doesn't always begin with a forward slash" do
        gh = generic_handler
        app << {pattern: '/ab', target: Class.new(Scorched::Controller) do
          map(pattern: 'out', target: gh)
        end}
        rt.get('/about').body.should == "ok"
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
        app << {pattern: '/', priority: -1, target: proc { |env| self.class.mappings.shift; [200, {}, ['four']] }}
        app << {pattern: '/', target: proc { |env| self.class.mappings.shift; [200, {}, ['two']] }}
        app << {pattern: '/', target: proc { |env| self.class.mappings.shift; [200, {}, ['three']] }}
        app << {pattern: '/', priority: 2, target: proc { |env| self.class.mappings.shift; [200, {}, ['one']] }}
        rt.get('/').body.should == 'one'
        rt.get('/').body.should == 'two'
        rt.get('/').body.should == 'three'
        rt.get('/').body.should == 'four'
      end
    end
    
    describe "conditions" do
      it "contains a default set of conditions" do
        app.conditions.should be_a(Options)
        app.conditions.should include(:methods, :media_type)
        app.conditions.each { |k,v| v.should be_a(Proc) }
      end
      
      it "executes route only if all conditions return true" do
        app << {pattern: '/', conditions: {methods: 'POST'}, target: generic_handler}
        response = rt.get "/"
        response.status.should == 404
        response = rt.post "/"
        response.status.should == 200
        
        app.conditions[:has_name] = proc { |name| request.GET['name'] }
        app << {pattern: '/about', conditions: {methods: ['GET', 'POST'], has_name: 'Ronald'}, target: generic_handler}
        response = rt.get "/about"
        response.status.should == 404
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
        app << {pattern: '/', conditions: {methods: 'POST'}, target: proc { |env| [200, {}, ['post']] }}
        app << {pattern: '/', conditions: {methods: 'GET'}, target: proc { |env| [200, {}, ['get']] }}
        rt.get("/").body.should == 'get'
        rt.post("/").body.should == 'post'
      end
    end
    
    describe "route helpers" do
      it "allows end points to be defined more succinctly" do
        route_proc = app.route('/*', 2, methods: 'GET') { |capture| capture }
        mapping = app.mappings.first
        mapping.should == {pattern: mapping[:pattern], priority: 2, conditions: {methods: 'GET'}, target: route_proc}
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
    end
    
    describe "sub-controllers" do
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
      
      it "inherits from parent class, or any other class" do
        app.controller.superclass.should == app
        app.controller('/', String).superclass.should == String
      end
      
      it "can take mapping options" do
        app.controller priority: -1, conditions: {methods: 'POST'} do
          route('/') { 'ok' }
        end
        app.mappings.first[:priority].should == -1
        rt.get('/').status.should == 404
        rt.post('/').body.should == 'ok'
      end
      
      it "should ignore the already matched portions of the path" do
        app.controller '/article' do
          get('/*') { |title| title }
        end
        rt.get('/article/hello-world').body.should == 'hello-world'
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
        app.before(methods: ['GET', 'PUT']) { counter += 1  }
        app.after(methods: ['GET', 'PUT']) { counter += 1  }
        rt.post('/')
        rt.get('/')
        rt.put('/')
        counter.should == 4
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
        
        example "before filters run from outermost to inner" do
          order = []
          app.before { order << :outer }
          app.controller { before { order << :inner } }
          rt.get('/')
          order.should == [:outer, :inner]
        end
        
        example "after filters run from innermost to outermost" do
          order = []
          app.after { order << :outer }
          app.controller { after { order << :inner } }
          rt.get('/')
          order.should == [:inner, :outer]
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
        app.error(methods: ['GET', 'PUT']) { true  }
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
        app.get('/') { halt 401 }
        rt.get('/').status.should == 401
      end
      
      it "skips processing filters" do
        app.after { response.status = 403 }
        app.get('/') { halt }
        rt.get('/').status.should == 200
      end
      
      it "short circuits filters if halted within filter" do
        app.before { halt }
        app.after { response.status = 403 }
        rt.get('/').status.should == 200
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
        app.controller '/sub' do
          after do
            response.body << 'hello'
            pass
          end
        end
        app.get('/sub') { response.body << ' there' }
        rt.get('/sub').body.should == 'hello there'
      end
      
      it "passing within filter of root controller results in uncaught symbol" do
        app.before { pass }
        expect {
          app.get('/') { }
          rt.get('/')
        }.to raise_error(ArgumentError)
      end
    end
    
    describe "configuration" do
      describe "strip_trailing_slash" do
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
      
      describe "static_dir" do
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
      
      describe "show_exceptions" do
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

      it "can render a file, relative to the application root" do
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

      it "takes an optional view directory, relative to the application root" do
        app.get('/') do
          render(:'main.erb', dir: 'views').should == "3 for me"
        end
        rt.get('/')
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
        rt.get('/').body.should == '({1 for none})'
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
      end
    end

  end
end