require_relative './helper.rb'

module Scorched
  describe Controller do
    let(:generic_handler) do
      proc { |env| [200, {}, ['ok']] }
    end
    
    it "contains a default set of configuration options" do
      app.config.should be_a(Hash)
      app.config.length.should > 0
    end
    
    it "contains a set of default conditions" do
      app.conditions.should be_a(Hash)
      app.conditions.length.should > 0
      app.conditions[:methods].should be_a(Proc)
    end
    
    describe "basic route handling" do
      it "gracefully handles 404 errors" do
        response = rt.get '/'
        response.status.should == 404
      end
    
      it "handles a root rack call correctly" do
        app << {url: '/$', target: generic_handler}
        response = rt.get '/'
        response.status.should == 200
      end
    
      it "does not maintain state between requests" do
        app << {url: '/state', target: proc { |env| [200, {}, [@state = 1 + @state.to_i]] }}
        response = rt.get '/state'
        response.body.should == '1'
        response = rt.get '/state'
        response.body.should == '1'
      end
      
      it "raises exception when invalid mapping hash given" do
        expect {
          app << {url: '/'}
        }.to raise_error(Scorched::Error)
        expect {
          app << {target: generic_handler}
        }.to raise_error(Scorched::Error)
      end
    end
    
    describe "URL matching" do
      it 'always matches from the beginning of the URL' do
        app << {url: 'about', target: generic_handler}
        response = rt.get '/about'
        response.status.should == 404
      end
      
      it "matches eagerly by default" do
        request = nil
        app << {url: '/*', target: proc do |env|
          request = env['rack.request']; [200, {}, ['ok']]
        end}
        response = rt.get '/about'
        request.captures.should == ['about']
      end
      
      it "can be configured to match lazily" do
        app.config[:match_lazily] = true
        request = nil
        app << {url: '/*', target: proc do |env|
          request = env['rack.request']; [200, {}, ['ok']]
        end}
        response = rt.get '/about'
        request.captures.should == ['a']
      end 
      
      it "can be forced to match end of URL" do
        app << {url: '/about$', target: generic_handler}
        response = rt.get '/about/us'
        response.status.should == 404
        app << {url: '/about', target: generic_handler}
        response = rt.get '/about/us'
        response.status.should == 200
      end
      
      it "can match anonymous wildcards" do
        request = nil
        app << {url: '/anon/*/**', target: proc do |env|
          request = env['rack.request']; [200, {}, ['ok']]
        end}
        response = rt.get '/anon/jeff/has/crabs'
        request.captures.should == ['jeff', 'has/crabs']
      end
      
      it "can match named wildcards (ignoring anonymous captures)" do
        request = nil
        app << {url: '/anon/:name/*/::infliction', target: proc do |env|
          request = env['rack.request']; [200, {}, ['ok']]
        end}
        response = rt.get '/anon/jeff/smith/has/crabs'
        request.captures.should == {name: 'jeff', infliction: 'has/crabs'}
      end
      
      it "can match regex and preserve anonymous captures" do
        request = nil
        app << {url: %r{/anon/([^/]+)/(.+)}, target: proc do |env|
          request = env['rack.request']; [200, {}, ['ok']]
        end}
        response = rt.get '/anon/jeff/has/crabs'
        request.captures.should == ['jeff', 'has/crabs']
      end
      
      it "can match regex and preserve named captures (ignoring anonymous captures)" do
        request = nil
        app << {url: %r{/anon/(?<name>[^/]+)/([^/]+)/(?<infliction>.+)}, target: proc do |env|
          request = env['rack.request']; [200, {}, ['ok']]
        end}
        response = rt.get '/anon/jeff/smith/has/crabs'
        request.captures.should == {name: 'jeff', infliction: 'has/crabs'}
      end
      
      it "matches routes based on priority, otherwise giving precedence to those defined first" do
        app << {url: '/', priority: -1, target: proc { |env| self.class.mappings.shift; [200, {}, ['four']] }}
        app << {url: '/', target: proc { |env| self.class.mappings.shift; [200, {}, ['two']] }}
        app << {url: '/', target: proc { |env| self.class.mappings.shift; [200, {}, ['three']] }}
        app << {url: '/', priority: 2, target: proc { |env| self.class.mappings.shift; [200, {}, ['one']] }}
        rt.get('/').body.should == 'one'
        rt.get('/').body.should == 'two'
        rt.get('/').body.should == 'three'
        rt.get('/').body.should == 'four'
      end
    end
    
    describe "conditions" do
      it "contains a default set of conditions" do
        app.conditions.should be_a(Hash)
        app.conditions.should include(:methods, :media_type)
        app.conditions.each { |k,v| v.should be_a(Proc) }
      end
      
      it "executes route only if all conditions return true" do
        app << {url: '/', conditions: {methods: 'POST'}, target: generic_handler}
        response = rt.get "/"
        response.status.should == 404
        response = rt.post "/"
        response.status.should == 200
        
        app.conditions[:has_name] = proc { |name| @request.GET['name'] }
        app << {url: '/about', conditions: {methods: ['GET', 'POST'], has_name: 'Ronald'}, target: generic_handler}
        response = rt.get "/about"
        response.status.should == 404
        response = rt.get "/about", name: 'Ronald'
        response.status.should == 200
      end
      
      it "raises exception when condition doesn't exist or is invalid" do
        app << {url: '/', conditions: {surprise_christmas_turkey: true}, target: generic_handler}
        expect {
          rt.get "/"
        }.to raise_error(Scorched::Error)
      end
      
      it "falls through to next route when conditions are not met" do
        app << {url: '/', conditions: {methods: 'POST'}, target: proc { |env| [200, {}, ['post']] }}
        app << {url: '/', conditions: {methods: 'GET'}, target: proc { |env| [200, {}, ['get']] }}
        rt.get("/").body.should == 'get'
        rt.post("/").body.should == 'post'
      end
    end
    
    describe "route helpers" do
      it "allows end points to be defined more succinctly" do
        route_proc = app.route('/*', 2, methods: 'GET') { |capture| capture }
        mapping = app.mappings.first
        mapping.should == {url: mapping[:url], priority: 2, conditions: {methods: 'GET'}, target: route_proc}
        rt.get('/about').body.should == 'about'
      end
      
      it "can provide a mapping proc without mapping it" do
        block = proc { |capture| capture }
        wrapped_block = app.route(&block)
        app.mappings.length.should == 0
        block.should_not == wrapped_block
        app << {url: '/*', target: wrapped_block}
        rt.get('/turkey').body.should == 'turkey'
      end
      
      it "provides a method for every HTTP method" do
        [:get, :post, :put, :delete, :options, :head, :patch].each do |m|
          app.send(m, '/say_cool') { 'cool' }
          rt.send(m, '/say_cool').body.should == 'cool'
        end
      end
      
      it "always matches to the end of the URL (implied $)" do
        app.get('/') { 'awesome '}
        rt.get('/dog').status.should == 404
        rt.get('/').status.should == 200
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
      
      it "can take mapping options" do
        app.controller priority: -1, conditions: {methods: 'POST'} do
          route('/') { 'ok' }
        end
        app.mappings.first[:priority].should == -1
        rt.get('/').status.should == 404
        rt.post('/').body.should == 'ok'
      end
      
      it "should ignore the already matched portions of the path" do
        app.controller url: '/article' do
          get('/*') { |title| title }
        end
        rt.get('/article/hello-world').body.should == 'hello-world'
      end
      
      it "inherits from parent class, or any other class" do
        app.controller.superclass.should == app
        app.controller(String).superclass.should == String
      end
    end
    
    describe "filters" do
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
    
    describe "middleware" do
      let(:app) do
        Class.new(Scorched::Controller) do
          self.middleware << proc { use Scorched::SimpleCounter }
          get '/$'do
            @request.env['scorched.simple_counter']
          end
          controller url: '/sub_controller' do
            get '/' do
              @request.env['scorched.simple_counter']
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
    
  end
end