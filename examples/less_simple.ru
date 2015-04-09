require File.expand_path('../../lib/scorched.rb', __FILE__)
require 'sequel'

Sequel::Model.db = Sequel.sqlite("development.db")

class Tasks < Sequel::Model
  db.create_table? :tasks do
    primary_key :id
    String :name
    DateTime :completed_at
  end
end

class App < Scorched::Controller
  controller '/tasks' do
    get '/' do
      @tasks = Tasks.all
      render :index
    end

    get '/:id' do
      render :task, locals: {task: task}
    end

    post '/' do
      id = Tasks.insert(:name => request.POST['name'])
      redirect "/tasks/#{id}" 
    end

    put '/:id' do
      task.update(completed_at: (request.POST['completed'] ? Time.now : nil), name: request.POST['name'])
      redirect "/tasks/#{captures[:id]}" 
    end

    delete '/:id' do
      task.delete
      redirect "/tasks" 
    end
    
    def task(id = captures[:id])
      Tasks[id] || halt(404)
    end
  end
end

run App