require 'json'
require File.expand_path('../../lib/scorched.rb', __FILE__)

class MediaTypesExample < Scorched::Controller
  
  get '/', media_type: 'text/html' do
    <<-HTML
      <div><strong>Name: </strong> John Falkon</div>
      <div><strong>Age: </strong> 39</div>
      <div><strong>Occupation: </strong> Carpet Cleaner</div>
    HTML
  end
  
  controller '/*' do
    get '/*' do |*captures|
      request.breadcrumb.inspect
    end
  end
  
  get '/', media_type: 'application/json' do
    {name: 'John Falkon', age: 39, occupation: 'Carpet Cleaner'}.to_json
  end
  
end

run MediaTypesExample