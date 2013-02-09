module Scorched
  class Controller
    include Scorched::Options('config')
    include Scorched::Options('conditions')
    include Scorched::Options('middleware')
    
    self.config = {
      # Applies only when the a forward slash directly follows the matched portion of the URL. If the pattern match includes
      # the trailing URL, or the unmatched portion of the URL does not begin with a forward slash, this setting has affect.
      :strip_trailing_slash => true, #=> Redirects URL ending in forward slash to URL not ending in forward slash.
      :match_lazily => false, # If true, compiles wildcards to match lazily.
    }
    
    self.conditions = {
      :methods => proc { |accepts| [*accepts].include?(@request.request_method) },
      :media_types => proc { |types| [*types].any? { |type| @request.env['rack-accept.request'].media_type? type } }
    }
    
    self.middleware = {
      Rack::Accept => true
    }
    
    class << self

      def mappings
        @mappings ||= []
      end
      
      def filters
        @filters ||= Hash.new { |h,k| h[k] = [] }
      end
      
      def call(env)
        app = lambda do |env|
          instance = self.new(env)
          instance.action
        end
        unless @builder 
          @builder = Rack::Builder.new
          middleware.select { |k,v| v == true }.keys.each do |mw|
            @builder.use(mw)
            middleware[mw] = false
          end
        end
        
        @builder.run(app)
        @builder.call(env)
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
        parent = args.first || Controller
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
          mapping[:conditions] = args.pop if Hash === args.last
          mapping[:priority] = args.pop if args.length == 2
          self.map mapping.merge(url: compile(args.first), target: target)
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
      
      def filter(type, conditions = {}, &block)
         filters[type.to_sym] << {conditions: conditions, proc: block}
      end
      
      ['before', 'after'].each do |type|
        define_method(type) do |conditions = {}, &block|
          filter(type, conditions, &block)
        end
      end
      
    private
    
      # Parses and compiles the given URL string pattern into a regex if not already, returning the resulting regexp
      # object. Accepts an optional block which is yielded to directly before the string is converted to a regex. The
      # block must return a value compatible with _Regexp.new_.
      def compile(url)
        return nil if url.nil?
        return url if Regexp === url
        lazy = config[:match_lazily] ? '?' : ''
        match_to_end = !!url.sub!(/\$$/, '')
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
        Regexp.new(block_given? ? yield(pattern) : pattern)
      end
    end
    
    def initialize(env)
      @request = env['rack.request'] ||= Request.new(env)
      @response = env['rack.response'] ||= Response.new
    end
    
    def action
      match = matches(true).first
      self.class.filters[:before].each { |f| instance_exec(&f[:proc]) if check_conditions?(f[:conditions]) }
      if match
        @request.breadcrumb << match
        # Proc's are executed in the context of this controller instance.
        target = match[:mapping][:target]
        @response.merge! (Proc === target) ? instance_exec(@request.env, &target) : target.call(@request.env)
      else
        @response.status = 404
      end
      self.class.filters[:after].each { |f| instance_exec(&f[:proc]) if check_conditions?(f[:conditions]) }
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
      self.class.mappings.each do |m|
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
        conds.all? do |c,v|
          raise Error, "The condition `#{c}` either does not exist, or is not a Proc object" unless Proc === self.conditions[c]
          instance_exec(v, &self.conditions[c])
        end
      end
    end

  end
end