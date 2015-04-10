require 'roda'
require_relative './common'

class App < Roda
  plugin :render
  plugin :all_verbs
  use Rack::MethodOverride

  route do |r|
    r.root do
      render :index
    end

    r.is 'artist/:id' do |artist_id|
      @artist = Artist[artist_id]
      check_access(@artist)

      r.get do
        render :artist
      end

      r.post do
        @artist.update(r['artist'])
        r.redirect '?POST'
      end

      r.delete do
        @artist.destroy
        r.redirect '?DELETE'
      end
    end
  end
end

run App
