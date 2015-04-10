require 'scorched'
require_relative './common'

class App < Scorched::Controller
  get '/' do
    render :index
  end

  controller '/artist/:id' do
    before do
      @artist = Artist[captures[:id]]
      check_access(@artist)
    end

    get '/' do
      render :artist
    end

    post '/' do
      @artist.update(request.POST)
    end

    delete '/' do
      @artist.destroy
    end

    after method!: 'GET' do
      redirect "?#{request.request_method}"
    end
  end
end

run App
