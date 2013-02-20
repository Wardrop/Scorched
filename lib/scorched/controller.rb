require 'set'
require 'logger'

module Scorched
  class Controller
    include Scorched::Options('config')
    include Scorched::Options('view_config')
    include Scorched::Options('conditions')
    include Scorched::Collection('middleware')
    include Scorched::Collection('before_filters')
    include Scorched::Collection('after_filters')
    include Scorched::Collection('error_filters')
    
    config << {
      :strip_trailing_slash => :redirect, # :redirect => Strips and redirects URL ending in forward slash, :ignore => internally ignores trailing slash, false => does nothing.
      :match_lazily => false, # If true, compiles wildcards to match lazily.
      :static_dir => 'public', # The directory Scorched should serve static files from. Set to false if web server or anything else is serving static files.
      :logger => Logger.new(STDOUT)
    }
    
    view_config << {
      :dir => 'views', # The directory containing all the view templates.
      :layout => false, # The default layout template to use. Set to false for no default layout.
    }
    
    conditions << {
      charset: proc { |charsets|
        [*charsets].any? { |charset| @request.env['rack-accept.request'].charset? charset }
      },
      encoding: proc { |encodings|
        [*encodings].any? { |encoding| @request.env['rack-accept.request'].encoding? encoding }
      },
      host: proc { |host| 
        (Regexp === host) ? host =~ @request.host : host == @request.host 
      },
      language: proc { |languages|
        [*languages].any? { |language| @request.env['rack-accept.request'].language? language }
      },
      media_type: proc { |types|
        [*types].any? { |type| @request.env['rack-accept.request'].media_type? type }
      },
      methods: proc { |accepts| 
        [*accepts].include?(@request.request_method)
      },
      user_agent: proc { |user_agent| 
        (Regexp === user_agent) ? user_agent =~ @request.user_agent : user_agent == @request.user_agent 
      },
      status: proc { |statuses| 
        [*statuses].include?(@response.status)
      },
    }
    
    self.middleware << proc { |this|
      use Rack::Accept
      use Rack::Static, :root => this.config[:static_dir] if this.config[:static_dir]
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
      
      # A hash including the keys :url and :target. Optionally takes the following keys
      #   :priority - Negative or positive integer for giving a priority to the mapped item.
      #   :conditions - A hash of condition:value pairs
      # Raises a Scorched::Error if invalid hash is given.
      def map(mapping)
        unless Hash === mapping && [:url, :target].all? { |k| mapping.keys.include? k }
          raise Scorched::Error, "Invalid mapping hash given: #{mapping}"
        end
        mapping[:url] = compile(mapping[:url])
        mapping[:priority] = mapping[:priority].to_i
        insert_idx = mappings.take_while { |v| mapping[:priority] <= v[:priority]  }.length
        mappings.insert(insert_idx, mapping)
      end
      alias :<< :map
      
      # Takes a mandatory block, and three optional arguments: a url, parent class of the anonymous controller and a
      # mapping hash. Any of the arguments can be ommited. As long as they're in the right order, the object type is
      # used to determine the argument(s) given.
      def controller(*args, &block)
        mapping = (Hash === args.last) ? args.pop : {} 
        parent = args.first || self
        c = Class.new(parent, &block)
        self << {url: '/', target: c}.merge(mapping)
        c
      end
      
      # Returns a new route proc from the given block.
      # If arguments are given, they are used to map the route to the current controller.
      # First argument is the URL to map to. Second argument is an optional priority. Last argument is an optional hash
      # of options.
      def route(*args, &block)
        target = proc do |env|
          env['rack.response'].body << instance_exec(*env['rack.request'].captures, &block)
          env['rack.response']
        end

        unless args.empty?
          mapping = {}
          mapping[:url] = compile(args.first, true)
          mapping[:conditions] = args.pop if Hash === args.last
          mapping[:priority] = args.pop if args.length == 2
          mapping[:target] = target
          self << mapping
        end
        
        target
      end

      ['get', 'post', 'put', 'delete', 'head', 'options', 'patch'].each do |method|
        methods = (method == 'get') ? ['GET', 'HEAD'] : [method.upcase]
        define_method(method) do |*args, &block|
          args << {} unless Hash === args.last
          args.last.merge!(methods: methods)
          route(*args, &block)
        end
      end
      
      def filter(type, *args, &block)
        conditions = (Hash === args.last) ? args.pop : {}
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
        lazy = config[:match_lazily] ? '?' : ''
        match_to_end = !!url.sub!(/\$$/, '') || match_to_end
        pattern = url.split(%r{(\*{1,2}|(?<!\\):{1,2}[^/*$]+)}).each_slice(2).map { |unmatched, match|
          Regexp.escape(unmatched) << begin
            if %w{* **}.include? match
              match == '*' ? "([^/]+#{lazy})" : "(.+#{lazy})"
            elsif match
              match[0..1] == '::' ? "(?<#{match[2..-1]}>.+#{lazy})" : "(?<#{match[1..-1]}>[^/]+#{lazy})"
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
      @request = env['rack.request'] ||= Request.new(env)
      @response = env['rack.response'] ||= Response.new
    end
    
    def action
      inner_error = nil
      rescue_block = proc do |e|
        raise e unless filters[:error].any? do |f|
          (f[:args].empty? || f[:args].any? { |type| e.is_a?(type) }) && check_conditions?(f[:conditions]) && instance_exec(e, &f[:proc])
        end
      end
      
      match = matches(true).first
      begin
        catch(:halt) do
          if config[:strip_trailing_slash] == :redirect && @request.path[-1] == '/'
            redirect(@request.path.chomp('/'))
          elsif config[:strip_trailing_slash] == :ignore
            @request.path.chomp('/')
          end
          
          run_filters(:before)
          if match
            @request.breadcrumb << match
            # Proc's are executed in the context of this controller instance.
            target = match[:mapping][:target]
            begin
              catch(:halt) do
                @response.merge! (Proc === target) ? instance_exec(@request.env, &target) : target.call(@request.env)
              end
            rescue => inner_error
              rescue_block.call(inner_error)
            end
          else
            @response.status = 404
          end
          run_filters(:after)
        end
      rescue => outer_error
        rescue_block.call(outer_error) unless outer_error == inner_error
      end
      @response
    end
    
    def match?
      !matches(true).empty?
    end
    
    # Finds mappings that match the currently unmatched portion of the request path, returning an array of all matches.
    # If _short_circuit_ is set to true, it stops matching at the first positive match, returning only a single match.
    def matches(short_circuit = false)
      to_match = @request.unmatched_path
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
      @response['Location'] = url
      halt(status)
    end
    
    def halt(status = 200)
      @response.status = status
      throw :halt
    end
    
    # Syntactic shorthand for accessing Rack env hash.
    def env
      @request.env
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