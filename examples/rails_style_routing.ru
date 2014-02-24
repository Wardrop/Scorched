require File.expand_path('../../lib/scorched.rb', __FILE__)

class App < Scorched::Controller
end

class Base < App
  def self.inherited(klass)
    klass.get('/') { invoke_action :index }
    klass.get('/new') { invoke_action :new }
    klass.post('/') { invoke_action :create }
    klass.get('/:id') { invoke_action :show }
    klass.get('/:id/edit') { invoke_action :edit }
    klass.route('/:id', method: ['PATCH', 'PUT']) { invoke_action :update }
    klass.delete('/:id') { invoke_action :delete }
  end
  
  def invoke_action(action)
    respond_to?(action) ? send(action) : pass
  end
end

class Root < Base
  def index
    'Hello'
  end
  
  def create
    'Creating it now'
  end
end

class Customer < Base
  def index
    'Hello customer'
  end
end

class Order < Base
  def index
    'Me order'
  end
end

App.controller '/customer', Customer
App.controller '/order', Order
App.controller '/', Root

run App