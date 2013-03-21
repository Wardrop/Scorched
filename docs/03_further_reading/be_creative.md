Be Creative
===========
Getting the most out of Scorched requires a bit of creative thinking. A couple of examples are given below.

Effortless REST
---------------
An DRY way to serve multiple content-types:

    # ruby
    class App < Scorched::Controller
      def view(view = nil)
        view ? env['app.view'] = view : env['app.view']
      end
      
      after do
        data = response.body.join('')
        response['Content-type'] = 'text/html'
        if check_condition?(:media_type, 'text/html')
          response.body = render(view, locals: {data: data})
        elsif check_condition?(:media_type, 'application/json')
          response['Content-type'] = 'application/json'
          response.body = data.to_json
        elsif check_condition?(:media_type, 'application/pdf')
          response['Content-type'] = 'text/plain'
          response.status = 406
          response.body = 'PDF rendering service currently unavailable.'
        else
          response.body = render(view, locals: {data: data})
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
  

Authentication and Permissions
------------------------------

_Example coming soon I hope._