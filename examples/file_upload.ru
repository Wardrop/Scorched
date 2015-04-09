require File.expand_path('../../lib/scorched.rb', __FILE__)
require 'mimemagic'

class MediaTypesExample < Scorched::Controller
  
  get '/' do
    <<-HTML
      <form method="POST" action="#{absolute(request.matched_path)}" enctype="multipart/form-data">
        <input type="file" name="example_file" />
        <input type="submit" value="Submit" />
      </form>
    HTML
  end
  
  post '/' do
    example_file = request[:example_file]
    mime = MimeMagic.by_magic(example_file[:tempfile])
    <<-HTML
      We know the following about the received file.
      <ul>
        <li><strong>Name:</strong> #{example_file[:filename]}</li>
        <li><strong>Supposed Type:</strong> #{example_file[:type]}</li>
        <li><strong>Actual Type:</strong> #{mime ? mime.type : "Unknown"}</li>
        <li><strong>Size:</strong> #{format_byte_size example_file[:tempfile].size}</li>
      </ul>
    HTML
  end
  
  # My self-proclaimed awesome byte size formatter: https://gist.github.com/Wardrop/4952405
  def format_byte_size(bytes, opts = {})
    opts = {binary: true, precision: 2, as_bits: false}.merge(opts)
    suffixes = ['bytes', 'KB', 'MB', 'GB', 'TB', 'PB','EB', 'ZB', 'YB']
    opts[:as_bits] && suffixes[0] = 'bits' && suffixes[1..-1].each { |v| v.downcase! } && bytes *= 8
    opts[:binary] ? base = 1024 : (base = 1000) && suffixes[1..-1].each { |v| v.insert(1,'i') }
    exp = bytes.zero? ? bytes : Math.log(bytes, base).floor
    "#{(bytes.to_f / (base ** exp)).round(opts[:precision])} #{suffixes[exp]}"
  end
  
end

run MediaTypesExample
