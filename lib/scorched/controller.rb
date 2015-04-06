require 'forwardable'

module Scorched
  TemplateCache = Tilt::Cache.new

  class Controller
    include Scorched::Options('config')
    include Scorched::Options('render_defaults')
    include Scorched::Options('conditions')
    include Scorched::Collection('middleware')
    include Scorched::Collection('before_filters')
    include Scorched::Collection('after_filters', true)
    include Scorched::Collection('error_filters')

    attr_reader :request, :response

    config << {
      :auto_pass => false, # Automatically _pass_ request back to outer controller if no route matches.
      :cache_templates => true,
      :logger => Logger.new(STDOUT),
      :show_exceptions => false,
      :show_http_error_pages => false, # If true, shows the default Scorched HTTP error page.
      :static_dir => false, # The directory Scorched should serve static files from. Set to false if web server or anything else is serving static files.
      :strip_trailing_slash => :redirect, # :redirect => Strips and redirects URL ending in forward slash, :ignore => internally ignores trailing slash, false => does nothing.

    }

    render_defaults << {
      :dir => 'views', # The directory containing all the view templates, relative to the current working directory.
      :layout => false, # The default layout template to use, relative to the view directory. Set to false for no default layout.
      :engine => :erb,
      :locals => {},
      :tilt => {default_encoding: 'UTF-8'}, # Options intended for Tilt. This gets around potential key name conflicts between Scorched and the renderer invoked by Tilt.
    }

    if ENV['RACK_ENV'] == 'development'
      config[:show_exceptions] = true
      config[:static_dir] = 'public'
      config[:cache_templates] = false
      config[:show_http_error_pages] = true
    end

    conditions << {
      charset: proc { |charsets|
        [*charsets].any? { |charset| env['rack-accept.request'].charset? charset }
      },
      config: proc { |map|
        map.all? { |k,v| config[k] == v }
      },
      content_type: proc { |content_types|
        [*content_types].include? env['CONTENT_TYPE']
      },
      encoding: proc { |encodings|
        [*encodings].any? { |encoding| env['rack-accept.request'].encoding? encoding }
      },
      failed_condition: proc { |conditions|
        if !matches.empty? && matches.any? { |m| m.failed_condition } && !@_handled
          [*conditions].include? matches.first.failed_condition[0]
        end
      },
      host: proc { |host|
        (Regexp === host) ? host =~ request.host : host == request.host
      },
      language: proc { |languages|
        [*languages].any? { |language| env['rack-accept.request'].language? language }
      },
      media_type: proc { |types|
        [*types].any? { |type| env['scorched.accept'][:accept].acceptable? type }
      },
      method: proc { |methods|
        [*methods].include?(request.request_method)
      },
      handled: proc { |bool|
        @_handled == bool
      },
      proc: proc { |blocks|
        [*blocks].all? { |b| instance_exec(&b) }
      },
      user_agent: proc { |user_agent|
        (Regexp === user_agent) ? user_agent =~ request.user_agent : user_agent == request.user_agent
      },
      status: proc { |statuses|
        [*statuses].include?(response.status)
      },
    }

    middleware << proc { |controller|
      use Rack::Head
      use Rack::MethodOverride
      use Rack::Accept
      use Scorched::Accept::Rack
      use Scorched::Static, controller.config[:static_dir] if controller.config[:static_dir]
      use Rack::Logger, controller.config[:logger] if controller.config[:logger]
      use Rack::ShowExceptions if controller.config[:show_exceptions]
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
          self.new(env).process
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
      #   :pattern - The url pattern to match on. Required.
      #   :target - A proc to execute, or some other object that responds to #call. Required.
      #   :priority - Negative or positive integer for giving a priority to the mapped item.
      #   :conditions - A hash of condition:value pairs
      # Raises ArgumentError if required key values are not provided.
      def map(pattern: nil, priority: nil, conditions: {}, target: nil)
        raise ArgumentError, "Mapping must specify url pattern and target" unless pattern && target
        mappings << {
          pattern: compile(pattern),
          priority: priority.to_i,
          conditions: conditions,
          target: target
        }
      end
      alias :<< :map

      # Maps a new ad-hoc or predefined controller.
      #
      # If a block is given, creates a new controller as a sub-class of _klass_ (_self_ by default), otherwise maps
      # _klass_ itself. Returns the new anonymous controller class if a block is given, or _klass_ otherwise.
      def controller(pattern = '/', klass = self, **mapping, &block)
        if block_given?
          controller = Class.new(klass, &block)
          controller.config[:auto_pass] = true if klass < Scorched::Controller
        else
          controller = klass
        end
        self << {pattern: pattern, target: controller}.merge(mapping)
        controller
      end

      # Generates and returns a new route proc from the given block, and optionally maps said proc using the given args.
      # Helper methods are provided for each HTTP method which automatically define the appropriate _:method_
      # condition.
      #
      # :call-seq:
      #     route(pattern = nil, priority = nil, **conds, &block)
      #     get(pattern = nil, priority = nil, **conds, &block)
      #     post(pattern = nil, priority = nil, **conds, &block)
      #     put(pattern = nil, priority = nil, **conds, &block)
      #     delete(pattern = nil, priority = nil, **conds, &block)
      #     head(pattern = nil, priority = nil, **conds, &block)
      #     options(pattern = nil, priority = nil, **conds, &block)
      #     patch(pattern = nil, priority = nil, **conds, &block)
      def route(pattern = nil, priority = nil, **conds, &block)
        target = lambda do
          args = captures.respond_to?(:values) ? captures.values : captures
          response.body = instance_exec(*args, &block)
          response
        end
        [*pattern].compact.each do |pattern|
          self << {pattern: compile(pattern, true), priority: priority, conditions: conds, target: target}
        end
        target
      end

      ['get', 'post', 'put', 'delete', 'head', 'options', 'patch', 'link', 'unlink'].each do |method|
        methods = (method == 'get') ? ['GET', 'HEAD'] : [method.upcase]
        define_method(method) do |*args, **conds, &block|
          conds.merge!(method: methods)
          route(*args, **conds, &block)
        end
      end

      # Defines a filter of +type+.
      # +args+ is used internally by Scorched for passing additional arguments to some filters, such as the exception in
      # the case of error filters.
      def filter(type, args: nil, force: nil, conditions: nil, **more_conditions, &block)
        more_conditions.merge!(conditions || {})
        filters[type.to_sym] << {args: args, force: force, conditions: more_conditions, proc: block}
      end

      # Syntactic sugar for defining a before filter.
      # If +force+ is true, the filter is run even if another filter halts the request.
      def before(force: false, **conditions, &block)
        filter(:before, force: force, conditions: conditions, &block)
      end

      # Syntactic sugar for defining an after filter.
      # If +force+ is true, the filter is run even if another filter halts the request.
      def after(force: false, **conditions, &block)
        filter(:after, force: force, conditions: conditions, &block)
      end

      # Syntactic sugar for defining an error filter.
      # Takes one or more optional exception classes for which this error filter should handle. Handles all exceptions
      # by default.
      def error(*classes, **conditions, &block)
        filter(:error, args: classes, conditions: conditions, &block)
      end

    private

      # Parses and compiles the given URL string pattern into a regex if not already, returning the resulting regexp
      # object. Accepts an optional _match_to_end_ argument which will ensure the generated pattern matches to the end
      # of the string.
      def compile(pattern, match_to_end = false)
        return pattern if Regexp === pattern
        raise Error, "Can't compile URL of type #{pattern.class}. Must be String or Regexp." unless String === pattern
        match_to_end = !!pattern.sub!(/\$$/, '') || match_to_end
        compiled = pattern.split(%r{(\*{1,2}\??|(?<!\\):{1,2}[^/*$]+\??)}).each_slice(2).map { |unmatched, match|
          Regexp.escape(unmatched) << begin
            op = (match && match[-1] == '?' && match.chomp!('?')) ? '*' : '+'
            if %w{* **}.include? match
              match == '*' ? "([^/]#{op})" : "(.#{op})"
            elsif match
              match[0..1] == '::' ? "(?<#{match[2..-1]}>.#{op})" : "(?<#{match[1..-1]}>[^/]#{op})"
            else
              ''
            end
          end
        }.join
        compiled << '$' if match_to_end
        Regexp.new(compiled)
      end
    end

    after(failed_condition: :host) { response.status = 404 }
    after(failed_condition: :method) { response.status = 405 }
    after(failed_condition: %i{charset encoding language media_type}) { response.status = 406 }

    def method_missing(method_name, *args, &block)
      (self.class.respond_to? method_name) ? self.class.__send__(method_name, *args, &block) : super
    end

    def respond_to_missing?(method_name, include_private = false)
      self.class.respond_to? method_name
    end

    def initialize(env)
      define_singleton_method :env do
        env
      end
      env['scorched.root_path'] ||= env['SCRIPT_NAME']
      @request = Request.new(env)
      @response = Response.new
    end

    # This is where the magic happens. Applies filters, matches mappings, applies error handlers, catches :halt and
    # :pass, etc.
    def process
      inner_error = nil
      rescue_block = proc do |e|
        (env['rack.exception'] = e && raise) unless filters[:error].any? do |f|
          if !f[:args] || f[:args].empty? || f[:args].any? { |type| e.is_a?(type) }
            instance_exec(e, &f[:proc]) unless check_for_failed_condition(f[:conditions])
          end
        end
      end

      begin
        catch(:halt) do
          if config[:strip_trailing_slash] == :redirect && request.path =~ %r{[^/]/+$}
            redirect(request.path.chomp('/'), 307)
          end
          eligable_matches = matches.reject { |m| m.failed_condition }
          pass if config[:auto_pass] && eligable_matches.empty?
          run_filters(:before)
          begin
            # Re-order matches based on media_type, ensuring priority and definition order are respected appropriately.
            eligable_matches.each_with_index.sort_by { |m,idx|
              [
                m.mapping[:priority] || 0,
                [*m.mapping[:conditions][:media_type]].map { |type|
                  env['scorched.accept'][:accept].rank(type, true)
                }.max || 0,
                -idx
              ]
            }.reverse.each { |match,idx|
              request.breadcrumb << match
              catch(:pass) {
                catch(:halt) do
                  dispatch(match)
                end
                @_handled = true
              }
              break if @_handled
              request.breadcrumb.pop
            }
            unless @_handled
              response.status = (!matches.empty? && eligable_matches.empty?) ? 403 : 404
            end
          rescue => inner_error
            rescue_block.call(inner_error)
          end
          run_filters(:after)
          true
        end || begin
          run_filters(:before, true)
          run_filters(:after, true)
        end
      rescue => outer_error
        outer_error == inner_error ? raise : catch(:halt) { rescue_block.call(outer_error) }
      end
      response.finish
    end

    # Dispatches the request to the matched target.
    # Overriding this method provides the oppurtunity for one to have more control over how mapping targets are invoked.
    def dispatch(match)
      target = match.mapping[:target]
      response.merge! begin
        if Proc === target
          instance_exec(&target)
        else
          target.call(env.merge(
            'SCRIPT_NAME' => request.matched_path.chomp('/'),
            'PATH_INFO' => request.unmatched_path[match.path.chomp('/').length..-1]
          ))
        end
      end
    end

    # Finds mappings that match the unmatched portion of the request path, returning an array of `Match` objects, or an
    # empty array if no matches were found.
    #
    # The `:eligable` attribute of the `Match` object indicates whether the conditions for that mapping passed.
    # The result is cached for the life time of the controller instance, for the sake of effecient recalling.
    def matches
      return @_matches if @_matches
      to_match = request.unmatched_path
      to_match = to_match.chomp('/') if config[:strip_trailing_slash] == :ignore && to_match =~ %r{./$}
      @_matches = mappings.map { |mapping|
        mapping[:pattern].match(to_match) do |match_data|
          if match_data.pre_match == ''
            if match_data.names.empty?
              captures = match_data.captures
            else
              captures = Hash[match_data.names.map{|v| v.to_sym}.zip match_data.captures]
            end
            Match.new(mapping, captures, match_data.to_s, check_for_failed_condition(mapping[:conditions]))
          end
        end
      }.compact
    end

    # Tests the given conditions, returning the name of the first failed condition, or nil otherwise.
    def check_for_failed_condition(conds)
      failed = (conds || []).find { |c, v| !check_condition?(c, v) }
      if failed
        failed[0] = failed[0][0..-2].to_sym if failed[0][-1] == '!'
      end
      failed
    end

    # Test the given condition, returning true if the condition passes, or false otherwise.
    def check_condition?(c, v)
      c = c[0..-2].to_sym if invert = (c[-1] == '!')
      raise Error, "The condition `#{c}` either does not exist, or is not an instance of Proc" unless Proc === self.conditions[c]
      retval = instance_exec(v, &self.conditions[c])
      invert ? !retval : !!retval
    end

    # Redirects to the specified path or URL. An optional HTTP status is also accepted.
    def redirect(url, status = (env['HTTP_VERSION'] == 'HTTP/1.1') ? 303 : 302)
      response['Location'] = absolute(url)
      halt(status)
    end

    # call-seq:
    #     halt(status=nil, body=nil)
    #     halt(body)
    def halt(status=nil, body=nil)
      unless status.nil? || Integer === status
        body = status
        status = nil
      end
      response.status = status if status
      response.body = body if body
      throw :halt
    end

    def pass
      throw :pass
    end

    # Convenience method for accessing Rack session.
    def session
      env['rack.session']
    end

    # Delegate a few common `request` methods for conveniance.
    extend Forwardable
    def_delegators :request, :captures

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

    after(force: true) do
      env['scorched.flash'].each { |k,v| session[k] = v } if session && env['scorched.flash']
    end

    # Serves as a thin layer of convenience to Rack's built-in method: Request#cookies, Response#set_cookie, and
    # Response#delete_cookie.
    #
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

    # Renders the given string or file path using the Tilt templating library.
    # Each option defaults to the corresponding value defined in _render_defaults_ attribute. Unrecognised options are
    # passed through to Tilt, but a `:tilt` option is also provided for passing options directly to Tilt.
    # The template engine is derived from the file name, or otherwise as specified by the _:engine_ option. If a string
    # is given, the _:engine_ option must be set.
    #
    # Refer to Tilt documentation for a list of valid template engines and Tilt options.
    def render(
      string_or_file,
      dir: render_defaults[:dir],
      layout: @_no_default_layout ? nil : render_defaults[:layout],
      engine: render_defaults[:engine],
      locals: render_defaults[:locals],
      tilt: render_defaults[:tilt],
      **options,
      &block
    )
      template_cache = config[:cache_templates] ? TemplateCache : Tilt::Cache.new
      tilt_options = options.merge(tilt || {})
      tilt_engine = (derived_engine = Tilt[string_or_file.to_s]) || Tilt[engine]
      raise Error, "Invalid or undefined template engine: #{engine.inspect}" unless tilt_engine

      template = if Symbol === string_or_file
        file = string_or_file.to_s
        file = file << ".#{engine}" unless derived_engine
        file = File.expand_path(file, dir) if dir

        template_cache.fetch(:file, tilt_engine, file, tilt_options) do
          tilt_engine.new(file, nil, tilt_options)
        end
      else
        template_cache.fetch(:string, tilt_engine, string_or_file, tilt_options) do
          tilt_engine.new(nil, nil, tilt_options) { string_or_file }
        end
      end

      # The following is responsible for preventing the rendering of layouts within views.
      begin
        original_no_default_layout = @_no_default_layout
        @_no_default_layout = true
        output = template.render(self, locals, &block)
      ensure
        @_no_default_layout = original_no_default_layout
      end

      if layout
        render(layout, dir: dir, layout: false, engine: engine, locals: locals, tilt: tilt, **options) { output }
      else
        output
      end
    end

    # Takes an optional URL, relative to the applications root, and returns a fully qualified URL.
    # Example: url('/example?show=30') #=> https://localhost:9292/myapp/example?show=30
    def url(path = nil)
      return path if path && URI.parse(path).scheme
      uri = URI::Generic.build(
        scheme: env['rack.url_scheme'],
        host: env['SERVER_NAME'],
        port: env['SERVER_PORT'].to_i,
        path: env['scorched.root_path'],
      )
      if path
        path[0,0] = '/' unless path[0] == '/'
        uri.to_s.chomp('/') << path
      else
        uri.to_s
      end
    end

    # Takes an optional path, relative to the applications root URL, and returns an absolute path.
    # Example: absolute('/style.css') #=> /myapp/style.css
    def absolute(path = nil)
      return path if path && URI.parse(path).scheme
      return_path = if path
        [env['scorched.root_path'], path].join('/').gsub(%r{/+}, '/')
      else
        env['scorched.root_path']
      end
      return_path[0] == '/' ? return_path : return_path.insert(0, '/')
    end

    # We always want this filter to run at the end-point controller, hence we include the conditions within the body of
    # the filter.
    after do
      if response.empty? && !check_for_failed_condition(config: {show_http_error_pages: true}, status: 400..599)
        response.body = <<-HTML
          <!DOCTYPE html>
          <html>
          <head>
            <style type="text/css">
             @import url(http://fonts.googleapis.com/css?family=Titillium+Web|Open+Sans:300italic,400italic,700italic,400,700,300);
              html, body { height: 100%; width: 100%; margin: 0; font-family: 'Open Sans', 'Lucida Sans', 'Arial'; }
              body { color: #333; display: table; }
              #container { display: table-cell; vertical-align: middle; text-align: center; }
              #container > * { display: inline-block; text-align: center; vertical-align: middle; }
              #logo {
                padding: 12px 24px 12px 120px; color: white; background: rgb(191, 64, 0);
                font-family: 'Titillium Web', 'Lucida Sans', 'Arial'; font-size: 36pt;  text-decoration: none;
              }
              h1 { margin-left: 18px; font-weight: 400; }
            </style>
          </head>
          <body>
            <div id="container">
              <a id="logo" href="http://scorchedrb.com">Scorched</a>
              <h1>#{response.status} #{Rack::Utils::HTTP_STATUS_CODES[response.status]}</h1>
            </div>
          </body>
          </html>
        HTML
      end
    end


  private

    def run_filters(type, forced_only = false)
      tracker = env['scorched.executed_filters'] ||= {before: Set.new, after: Set.new}
      filters[type].reject{ |f| tracker[type].include?(f) || (forced_only && !f[:force]) }.each do |f|
        unless check_for_failed_condition(f[:conditions])
          tracker[type] << f
          if forced_only
            catch(:halt) do
              instance_exec(&f[:proc]); true
            end or log.warn "Ignored halt while running forced filters."
          else
            instance_exec(&f[:proc])
          end
        end
      end
    end

    def log(type = nil, message = nil)
      config[:logger].progname ||= 'Scorched'
      if(type)
        type = Logger.const_get(type.to_s.upcase)
        config[:logger].add(type, message)
      end
      config[:logger]
    end
  end
end
