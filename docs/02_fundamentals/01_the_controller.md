The Controller
==============

Scorched consists almost entirely of the ``Scorched::Controller``. The Controller is the class from which your application class inherits. All the code examples provided in the documentation are assumed to be wrapped within a controller class.

    # ruby
    class MyApp < Scorched::Controller
      # We are now within the controller class.
      # Most examples are assumed to be within this context.
    end

Your application's root controller (named ``MyApp`` in the example above), should be configured as the _run_ target in your rackup file:

    # ruby
    # config.ru
    require './myapp.rb'
    run MyApp

The rest of the documentation will detail the Controller more thoroughly.