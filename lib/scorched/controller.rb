module Scorched
  class Controller
    include ViewHelpers
    include Scorched::Options('config')
    include Scorched::Options('view_config')
    include Scorched::Options('conditions')
    include Scorched::Collection('middleware')
    include Scorched::Collection('before_filters')
    include Scorched::Collection('after_filters')
    include Scorched::Collection('error_filters')
    
    config << {
      :strip_trailing_slash => :redirect, # :redirect => Strips and redirects URL ending in forward slash, :ignore => internally ignores trailing slash, false => does nothing.
      :static_dir => 'public', # The directory Scorched should serve static files from. Set to false if web server or anything else is serving static files.
      :logger => Logger.new(STDOUT)
    }
    
    view_config << {
      :dir => 'views', # The directory containing all the view templates, relative to the application root.
      :layout => false, # The default layout template to use, relative to the view directory. Set to false for no default layout.
      :engine => :erb
    }
    
    conditions << {
      charset: proc { |charsets|
        [*charsets].any? { |charset| request.env['rack-accept.request'].charset? charset }
      },
      encoding: proc { |encodings|
        [*encodings].any? { |encoding| request.env['rack-accept.request'].encoding? encoding }
      },
      host: proc { |host| 
        (Regexp === host) ? host =~ request.host : host == request.host 
      },
      language: proc { |languages|
        [*languages].any? { |language| request.env['rack-accept.request'].language? language }
      },
      media_type: proc { |types|
        [*types].any? { |type| request.env['rack-accept.request'].media_type? type }
      },
      methods: proc { |accepts| 
        [*accepts].include?(request.request_method)
      },
      user_agent: proc { |user_agent| 
        (Regexp === user_agent) ? user_agent =~ request.user_agent : user_agent == request.user_agent 
      },
      status: proc { |statuses| 
        [*statuses].include?(response.status)
      },
    }
    
    middleware << proc { |this|
      use Rack::Head
      use Rack::MethodOverride
      use Rack::Accept
      use Scorched::Static, :dir => this.config[:static_dir] if this.config[:static_dir]
      use Rack::Logger, this.config[:logger] if this.config[:logger]
    }
    
    class << self

      def mappings
        @mappings ||= []
      end
      
      def filters
        @filters ||= {before: before_filters, after: after_filters, error: error_filters}
      end
      
      def call(env)
        loaded = env['scorched.middleware'] ||= Set.new
        app = lambda do |env|
          instance = self.new(env)
          instance.action
        end

        builder = Rack::Builder.new
        middleware.reject{ |v| loaded.include? v }.each do |proc|
          builder.instance_exec(self, &proc)
          loaded << proc
        end
        builder.run(app)
        builder.call(env)
      end
      
      # Generates and assigns mapping hash from the given arguments.
      #
      # Accepts the following keyword arguments:
      #   :url - The url pattern to match on. Required.
      #   :target - A proc to execute, or some other object that responds to #call. Required.
      #   :priority - Negative or positive integer for giving a priority to the mapped item.
      #   :conditions - A hash of condition:value pairs
      # Raises ArgumentError if required key values are not provided.
      def map(url: nil, priority: nil, conditions: {}, target: nil)
        raise ArgumentError, "Mapping must specify url pattern and target" unless url && target
        priority = priority.to_i
        insert_pos = mappings.take_while { |v| priority <= v[:priority]  }.length
        mappings.insert(insert_pos, {
          url: compile(url),
          priority: priority,
          conditions: conditions,
          target: target
        })
      end
      alias :<< :map
      
      # Creates a new controller as a sub-class of self (by default), mapping it to self using the provided mapping
      # hash if one is provided. Returns the new anonymous controller class.
      #
      # Takes two optional arguments and a block: a parent class from which the generated controller class inherits
      # from, a mapping hash to automatically map the new controller, and of course a block which defines the
      # controller class.
      #
      # It's worth noting, however obvious, that the resulting class will only be a controller if the parent class is
      # (or inherits from) a Scorched::Controller.
      def controller(parent_class = self, **mapping, &block)
        c = Class.new(parent_class, &block)
        self << {url: '/', target: c}.merge(mapping)
        c
      end
      
      # Generates and returns a new route proc from the given block, and optionally maps said proc using the given args.
      def route(url = nil, priority = nil, **conditions, &block)
        target = lambda do |env|
          env['rack.response'].body << instance_exec(*env['rack.request'].captures, &block)
          env['rack.response']
        end
        self << {url: compile(url, true), priority: priority, conditions: conditions, target: target} if url
        target
      end

      ['get', 'post', 'put', 'delete', 'head', 'options', 'patch'].each do |method|
        methods = (method == 'get') ? ['GET', 'HEAD'] : [method.upcase]
        define_method(method) do |*args, **conditions, &block|
          conditions.merge!(methods: methods)
          route(*args, **conditions, &block)
        end
      end
      
      def filter(type, *args, **conditions, &block)
        filters[type.to_sym] << {args: args, conditions: conditions, proc: block}
      end
      
      # A bit of syntactic sugar for #filter.
      ['before', 'after', 'error'].each do |type|
        define_method(type) do |*args, &block|
          filter(type, *args, &block)
        end
      end
      
    private
    
      # Parses and compiles the given URL string pattern into a regex if not already, returning the resulting regexp
      # object. Accepts an optional _match_to_end_ argument which will ensure the generated pattern matches to the end
      # of the string.
      def compile(url, match_to_end = false)
        return url if Regexp === url
        raise Error, "Can't compile URL of type #{url.class}. Must be String or Regexp." unless String === url
        match_to_end = !!url.sub!(/\$$/, '') || match_to_end
        pattern = url.split(%r{(\*{1,2}|(?<!\\):{1,2}[^/*$]+)}).each_slice(2).map { |unmatched, match|
          Regexp.escape(unmatched) << begin
            if %w{* **}.include? match
              match == '*' ? "([^/]+)" : "(.+)"
            elsif match
              match[0..1] == '::' ? "(?<#{match[2..-1]}>.+)" : "(?<#{match[1..-1]}>[^/]+)"
            else
              ''
            end
          end
        }.join
        pattern << '$' if match_to_end
        Regexp.new(pattern)
      end
    end
    
    def method_missing(method, *args, &block)
      (self.class.respond_to? method) ? self.class.__send__(method, *args, &block) : super
    end
    
    def initialize(env)
      define_singleton_method :env do
        env
      end
      env['rack.request'] ||= Request.new(env)
      env['rack.response'] ||= Response.new
    end
    
    def action
      inner_error = nil
      rescue_block = proc do |e|
        raise unless filters[:error].any? do |f|
          (f[:args].empty? || f[:args].any? { |type| e.is_a?(type) }) && check_conditions?(f[:conditions]) && instance_exec(e, &f[:proc])
        end
      end
      
      match = matches(true).first
      begin
        catch(:halt) do
          if config[:strip_trailing_slash] == :redirect && request.path =~ %r{./$}
            redirect(request.path.chomp('/'))
          end
          
          run_filters(:before)
          if match
            request.breadcrumb << match
            # Proc's are executed in the context of this controller instance.
            target = match[:mapping][:target]
            begin
              catch(:halt) do
                response.merge! (Proc === target) ? instance_exec(request.env, &target) : target.call(request.env)
              end
            rescue => inner_error
              rescue_block.call(inner_error)
            end
          else
            response.status = 404
          end
          run_filters(:after)
        end
      rescue => outer_error
        outer_error == inner_error ? raise : rescue_block.call(outer_error)
      end
      response
    end
    
    def match?
      !matches(true).empty?
    end
    
    # Finds mappings that match the currently unmatched portion of the request path, returning an array of all matches.
    # If _short_circuit_ is set to true, it stops matching at the first positive match, returning only a single match.
    def matches(short_circuit = false)
      to_match = request.unmatched_path
      to_match = to_match.chomp('/') if config[:strip_trailing_slash] == :ignore && to_match =~ %r{./$}
      matches = []
      mappings.each do |m|
        m[:url].match(to_match) do |match_data|
          if match_data.pre_match == ''
            if check_conditions?(m[:conditions])
              if match_data.names.empty?
                captures = match_data.captures
              else
                captures = Hash[match_data.names.map{|v| v.to_sym}.zip match_data.captures]
              end
              matches << {mapping: m, captures: captures, url: match_data.to_s}
              break if short_circuit
            end
          end
        end
      end
      matches
    end
    
    def check_conditions?(conds)
      if !conds
        true
      else
        conds.all? { |c,v| check_condition?(c, v) }
      end
    end
    
    def check_condition?(c, v)
      raise Error, "The condition `#{c}` either does not exist, or is not a Proc object" unless Proc === self.conditions[c]
      instance_exec(v, &self.conditions[c])
    end
    
    def redirect(url, status = 307)
      response['Location'] = url
      halt(status)
    end
    
    def halt(status = 200)
      response.status = status
      throw :halt
    end
    
    # Convenience method for accessing Rack request.
    def request
      env['rack.request']
    end
    
    # Convenience method for accessing Rack response.
    def response
      env['rack.response']
    end
    
    # Convenience method for accessing Rack session.
    def session
      env['rack.session']
    end
    
    # Flash session storage helper.
    # Stores session data until the next time this method is called with the same arguments, at which point it's reset.
    # The typical use case is to provide feedback to the user on the previous action they performed.
    def flash(key = :flash)
      raise Error, "Flash session data cannot be used without a valid Rack session" unless session
      flash_hash = env['scorched.flash'] ||= {}
      flash_hash[key] ||= {}
      session[key] ||= {}
      unless session[key].methods(false).include? :[]=
        session[key].define_singleton_method(:[]=) do |k, v|
          flash_hash[key][k] = v
        end
      end
      session[key]
    end
    
    after do
      env['scorched.flash'].each { |k,v| session[k] = v } if session && env['scorched.flash']
    end
    
    # Serves a thin layer of convenience to Rack's built-in methods: Request#cookies, Response#set_cookie, and
    # Response#delete_cookie.
    # If only one argument is given, the specified cookie is retreived and returned.
    # If both arguments are supplied, the cookie is either set or deleted, depending on whether the second argument is
    # nil, or otherwise is a hash containing the key/value pair ``:value => nil``.
    # If you wish to set a cookie to an empty value without deleting it, you pass an empty string as the value
    def cookie(name, *value)
      name = name.to_s
      if value.empty?
        request.cookies[name]
      else
        value = Hash === value[0] ? value[0] : {value: value}
        if value[:value].nil?
          response.delete_cookie(name, value)
        else
          response.set_cookie(name, value)
        end
      end
    end
    
  private
  
    def run_filters(type)
      tracker = env['scorched.filters'] ||= {before: Set.new, after: Set.new}
      filters[type].reject{ |f| tracker[type].include? f }.each do |f|
        if check_conditions?(f[:conditions])
          tracker[type] << f
          instance_exec(&f[:proc])
        end
      end
    end
  end
end