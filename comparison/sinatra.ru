require 'sinatra/base'
require_relative './common'

class App < Sinatra::Base
  use Rack::MethodOverride

  get '/' do
    erb :index
  end

  get '/artist/:id' do
    @artist = Artist[params[:id]]
    check_access(@artist)
    erb :artist
  end

  post '/artist/:id' do
    @artist = Artist[params[:id]]
    check_access(@artist)
    @artist.update(params[:artist])
    redirect(request.path_info + '?POST')
  end

  delete '/artist/:id' do
    @artist = Artist[params[:id]]
    check_access(@artist)
    @artist.destory
    redirect(request.path_info + '?DELETE')
  end
end

run App
