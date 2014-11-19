# Simple Reactor

This is a simple, pure Ruby implementation of an event reactor for handling IO in an event oriented manner. It was originally written by Kirk Haines for an article on the Engine Yard blog about event based IO.  The original article can be found at

https://blog.engineyard.com/2011/what-are-events-why-might-you-care-and-how-can-eventmachine-help

## License

This code is being released under the MIT open source license.

## Contact

Kirk Haines <wyhaines@gmail.com>

## Bugs

There are no known bugs with this implementation at this time.  Report bugs in the github repository, please.

## Installation

    $ gem install simplereactor

## Common Use

Examples of usage can be found in the original article, referenced above. Below is a sample of a very stupid web server that's not even remotely standards compliant.

<code>
require './simplereactor'
require 'socket'

server = TCPServer.new("0.0.0.0", 9949)
buffer = ''

puts <<ETXT
Type some text and press after each line. The reactor is attached to
STDIN and also port 9949, where it listens for any connection and responds with
a basic HTTP response containing whatever has been typed to that point. These
two dramatically different IO streams are being handled simultaneously. Type
to exit, or wait one minute, and a timer will fire which causes the
reactor to stop and the program to exit.
ETXT

SimpleReactor.run do |reactor|
  reactor.attach(server, :read) do |server|
    conn = server.accept
    conn.gets # Pull all of the incoming data, even though it is not used in this example
    conn.write "HTTP/1.1 200 OK\r\nContent-Length:#{buffer.length}\r\nContent-Type:text/plain\r\nConnection:close\r\n\r\n#{buffer}"
    conn.close
  end

  characters_received = 0
  reactor.attach(STDIN, :read) do |stdin|
    characters_received += 1
    data = stdin.getc # Pull a character at a time, just for illustration purposes
    unless data
      reactor.stop
    else
      buffer << data
    end
  end

  reactor.add_timer(60) do
    reactor.stop
  end
end
</code>
