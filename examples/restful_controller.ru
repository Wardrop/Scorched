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
      klass.get('/:id/edit') { |id| invoke_action :edit, id }
      klass.route('/:id', method: ['PATCH', 'PUT']) { |id| invoke_action :update, id }
      klass.delete('/:id') { |id| invoke_action :delete, id }
    end

    def invoke_action(action, *captures)
      respond_to?(action) ? send(action, *captures) : pass
    end

  end
end

class Root < App
  include Scorched::RestActions

  def index
    'Hello'
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
