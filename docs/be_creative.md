Effortless REST
---------------
An easy way to serve multiple content-types:

  class App < Scorched::Controller
    def view(view = nil)
      view ? env['app.view'] = view : env['app.view']
    end
  
    after do
      if check_condition?(:media_type, 'text/html')
        @response.body = [render(view)]
      if check_condition?(:media_type, 'application/json')
        @response['Content-type'] = 'application/json'
        @response.body = [@response.body.to_json]
      elsif check_condition?(:media_type, 'application/pdf')
        @response['Content-type'] = 'application/pdf'
        # @response.body = [render_pdf(view)]
      else
        @response.body = [render(view)]
      end
    end
  
    get '/' do
      view :index
      [
        {title: 'Sweet Purple Unicorns', date: '08/03/2013'},
        {title: 'Mellow Grass Men', date: '21/03/2013'}
      ]
    end
  end
  
