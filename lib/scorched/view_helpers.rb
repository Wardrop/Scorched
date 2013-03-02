# In its own file for no other reason than to keep all the extra non-essential bells and whistles in their own file,
# which can be easily excluded if needed.

module Scorched
  module ViewHelpers
    
    # Renders the given string or file path using the Tilt templating library.
    # Options hash is merged with the controllers _view_config_. Tilt template options are passed through. 
    # The template engine is derived from file name, or otherwise as specified by the _:engine_ option. If String is
    # given, _:engine_ option must be set.
    #
    # Refer to Tilt documentation for a list of valid template engines.
    def render(string_or_file, options = {}, &block)
      options = view_config.merge(explicit_options = options)
      engine = (derived_engine = Tilt[string_or_file.to_s]) || Tilt[options[:engine]]
      raise Error, "Invalid or undefined template engine: #{options[:engine].inspect}" unless engine
      if Symbol === string_or_file
        file = string_or_file.to_s
        file = file << ".#{options[:engine]}" unless derived_engine
        file = File.join(options[:dir], file) if options[:dir]
        template = engine.new(file, nil, options)
      else
        template = engine.new(nil, nil, options) { string_or_file }
      end
      
      # The following chunk of code is responsible for preventing the rendering of layouts within views.
      options[:layout] = false if @_no_default_layout && !explicit_options[:layout]
      begin
        @_no_default_layout = true
        output = template.render(self, options[:locals], &block)
      ensure
        @_no_default_layout = false
      end
      output = render(options[:layout], options.merge(layout: false)) { output } if options[:layout]
      output
    end
    
  end
end