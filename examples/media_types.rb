require 'json'
require_relative '../lib/scorched.rb'

class MediaTypesExample < Scorched::Controller
  
  get '/', media_type: 'text/html' do
    <<-HTML
      <div><strong>Name: </strong> John Falkon</div>
      <div><strong>Age: </strong> 39</div>
      <div><strong>Occupation: </strong> Carpet Cleaner</div>
      #{@request.env['scorched.simple_counter']}
    HTML
  end
  
  get '/,', media_type: 'application/json' do
    {name: 'John Falkon', age: 39, occupation: 'Carpet Cleaner'}.to_json
  end
  
end