Running a Live Console
======================

Scorched does not include a console like Rails or Merb does, but only because it doesn't need to. Multiple solutions already exist, including simply loading your application within IRB or Pry.

First, I suggest you try [Racksh](https://github.com/sickill/racksh). It's a very handy yet simple Rack shell implementation that should meet most of your expectations. You can install _racksh_ as a gem with `gem install racksh`. I suggest you read the README in the projects Github repository to get started.

Another option for those running Phusion Passenger Enterprise, is the live IRB and debugging console. An introductory video can be found here: http://vimeo.com/45923773