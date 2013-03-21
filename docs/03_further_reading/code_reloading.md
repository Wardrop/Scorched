Code Reloading
==============

The difficulties, or rather impossibilities, of doing in-process code reloading in Ruby have been well-documented. Scorched therefore makes no attempt to implement in form of such code reloading. There are many out-of-process reloading solutions. These all essentially reboot your application, reloading all dependancies. This provides an obvious incentive to keep your application boot times as fast as possible.

A sub-set of the most popular application reloaders are detailed below.

Rerun
-----
Rerun is a general purpose gem (``gem install rerun``) for watching files and rerunning some command when any of those files change. The following example uses rerun to watch for changes to ".rb" and ".ru" files anywhere in the current directory tree. If a change is made, any previous instance of ``rackup`` are shutdown and restarted.

    rerun -p "**/*.{rb,ru}" rackup

Shotgun
-------
Unlike Rerun, Shotgun doesn't do any file watching. It instead reloads your application on every request. This sounds slow, but rerun uses an efficient technique of forking the application server and reloading your application. For applications that are quick to start, this method is generally preferred. Shotgun was used for example while developing http://scorchedrb.com.

    shotgun

Phusion Passenger
-----------------
The popular Apache/Nginx module for hosting Rack applications, Phusion Passenger, can be configured to reload your application on every request much like Shotgun does. Passenger can be faster that Shogun, as you can let the underlying web server (Apache or Nginx) to take care of the static file serving, which avoids having to reload your application for every static file request.

To have Passenger automatically restart your application on every request, create a file named ``tmp/always_restart.txt`` in the root of your application directory. Passenger will automatically detect this file and behave as intended.