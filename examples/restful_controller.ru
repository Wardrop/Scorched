require File.expand_path('../../lib/scorched.rb', __FILE__)

class App < Scorched::Controller
end

module Scorched
  module RestActions
    def self.included(klass)
      klass.get('/') { invoke_action :index }
      klass.get('/new') { invoke_action :new }
      klass.post('/') { invoke_action :create }
      klass.get('/:id') { |id| invoke_action :show, id }
      klass.get('/:id/edit') { invoke_action :edit }
      klass.route('/:id', method: ['PATCH', 'PUT']) { invoke_action :update }
      klass.delete('/:id') { invoke_action :delete }
    end

    def invoke_action(action, *captures)
      respond_to?(action) ? send(action, *captures) : pass
    end
  end
end

class Root < App
  def index
    'Hello'
  end

  def create
    'Creating it now'
  end
end

class Customer < App
  include Scorched::RestActions
  def index
    'Hello customer'
  end

  def show(id)
    "Hello customer #{id}"
  end
end

App.controller '/customer', Customer
App.controller '/', Root

run App
