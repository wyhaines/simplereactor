require 'simplereactor'
require 'tinytypes'
require 'getoptlong'
require 'socket'
require 'time'

class SimpleWebServer

  attr_reader :threaded

  EXE = File.basename __FILE__
  VERSION = "1.0"

  def self.parse_cmdline
    initialize_defaults

    opts = GetoptLong.new(
      [ '--help',      '-h', GetoptLong::NO_ARGUMENT],
      [ '--threaded',  '-t', GetoptLong::NO_ARGUMENT],
      [ '--processes', '-n', GetoptLong::REQUIRED_ARGUMENT],
      [ '--engine',    '-e', GetoptLong::REQUIRED_ARGUMENT],
      [ '--port',      '-p', GetoptLong::REQUIRED_ARGUMENT],
      [ '--docroot',   '-d', GetoptLong::REQUIRED_ARGUMENT]
    )

    opts.each do |opt, arg|
      case opt
      when '--help'
        puts <<-EHELP
#{EXE} [OPTIONS]

#{EXE} is a very simple web server. It only serves static files. It does very
little parsing of the HTTP request, only fetching the small amount of
information necessary to determine what resource is being requested. The server
defaults to serving files from the current director when it was invoked.

-h, --help:
  Show this help.

-d DIR, --docroot DIR:
  Provide a specific directory for the docroot for this server.

-e ENGINE, --engine ENGINE:
  Tell the webserver which IO engine to use. This is passed to SimpleReactor,
  and will be one of 'select' or 'nio'. If not specified, it will attempt to
  use nio, and fall back on select.

-p PORT, --port PORT:
  The port for the web server to listen on. If this flag is not used, the web
  server defaults to port 80.

-b HOSTNAME, --bind HOSTNAME:
  The hostname/IP to bind to. This defaults to 127.0.0.1 if it is not provided.

-n COUNT, --processes COUNT:
  The number of processess to create of this web server. This defaults to a single process.

-t, --threaded:
  Wrap content deliver in a thread to hedge against slow content delivery.
EHELP
        exit
      when '--docroot'
        @docroot = arg
      when '--engine'
        @engine = arg
      when '--port'
        @port = arg.to_i != 0 ? arg.to_i : @port
      when '--bind'
        @host = arg
      when '--processes'
        @processes = arg.to_i != 0 ? arg.to_i : @port
      when '--threaded'
        @threaded = true
      end
    end
  end

  def self.initialize_defaults
    @docroot = '.'
    @engine = 'nio'
    @port = 80
    @host = '127.0.0.1'
    @processes = 1
    @threaded = false
  end

  def self.docroot
    @docroot
  end

  def self.engine
    @engine
  end

  def self.port
    @port
  end

  def self.host
    @host
  end

  def self.processes
    @processes
  end

  def self.threaded
    @threaded
  end

  def self.run
    parse_cmdline

    SimpleReactor.use_engine @engine.to_sym

    webserver = SimpleWebServer.new

    webserver.run
  end

  def initialize
    @children = nil
    @docroot = self.class.docroot
    @threaded = self.class.threaded
  end

  def run
    @server = TCPServer.new self.class.host, self.class.port

    handle_processes

    SimpleReactor.Reactor.run do |reactor|
      @reactor = reactor
      @reactor.attach @server, :read do |monitor|
        connection = monitor.io.accept
        handle_request '',connection, monitor
      end
    end 
  end

  def handle_request buffer, connection, monitor = nil
    eof = false
    buffer << connection.read_nonblock(16384)
  rescue EOFError
    eof = true
  rescue IO::WaitReadable
    # This is actually handled in the logic below. We just need to survive it.
  ensure
    request = parse_request buffer, connection
    if !request && monitor
      @reactor.next_tick do
        @reactor.attach connection, :read do |mon|
          handle_request buffer, connection
        end
      end
    elsif eof && !request
      deliver_400 connection
    elsif request
      handle_response_for request, connection
    end

    if eof
      queue_detach connection
    end
  end

  def queue_detach connection
      @reactor.next_tick do
        @reactor.detach(connection)
        connection.close
      end
  end

  def handle_response_for request, connection
    path = File.join( @docroot, request[:uri] )
    if FileTest.exist?( path ) and FileTest.file?( path ) and File.expand_path( path ).index( @docroot ) == 0

      deliver path, connection
    else
      deliver_404 path, connection
    end
  end

  def parse_request buffer, connection
    if buffer =~ /^(\w+) +(?:\w+:\/\/([^ \/]+))?([^ \?\#]*)\S* +HTTP\/(\d\.\d)/
      request_method = $1
      uri = $3
      http_version = $4
      if $2
        name = $2.intern
        uri = C_slash if @uri.empty?
        # Rewrite the request to get rid of the http://foo portion.
        buffer.sub!(/^\w+ +\w+:\/\/[^ \/]+([^ \?]*)/,"#{@request_method} #{@uri}")
        buffer =~ /^(\w+) +(?:\w+:\/\/([^ \/]+))?([^ \?\#]*)\S* +HTTP\/(\d\.\d)/
        request_method = $1
        uri = $3
        http_version = $4
      end
      uri = uri.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) {[$1.delete('%')].pack('H*')} if uri.include?('%')
      unless name
        if buffer =~ /^Host: *([^\r\0:]+)/
          name = $1.intern
        end
      end

      { :uri => uri, :request_method => request_method, :http_version => http_version, :name => name }
    end
  end

  def deliver uri, connection
    if FileTest.directory? uri
      deliver_directory connection
    else
      if threaded
        Thread.new { _deliver uri, connection }
      else
        _deliver uri, connection
      end
    end
  rescue Errno::EPIPE
  rescue Exception => e
    deliver_500 connection, e
  end

  def _deliver uri, connection
    data = File.read(uri)
    last_modified = File.mtime(uri).httpdate
    sleep 1
    connection.write "HTTP/1.1 200 OK\r\nContent-Length:#{data.length}\r\nContent-Type: #{content_type_for uri}\r\nLast-Modified: #{last_modified}\r\nConnection:close\r\n\r\n#{data}"
    queue_detach connection
  end

  def deliver_directory
    deliver_403 connection
  end

  def deliver_404 uri, connection
    buffer = "The requested resource (#{uri}) could not be found."
    connection.write "HTTP/1.1 404 Not Found\r\nContent-Length:#{buffer.length}\r\nContent-Type:text/plain\r\nConnection:close\r\n\r\n#{buffer}"
  rescue Errno::EPIPE
  ensure
    queue_detach connection
  end

  def deliver_400 connection
    buffer = "The request was malformed and could not be completed."
    connection.write "HTTP/1.1 400 Bad Request\r\nContent-Length:#{buffer.length}\r\nContent-Type:text/plain\r\nConnection:close\r\n\r\n#{buffer}"
  rescue Errno::EPIPE
  ensure
    queue_detach connection
  end

  def deliver_403 connection
    buffer = "Forbidden. The requested resource can not be accessed."
    connection.write "HTTP/1.1 403 Bad Request\r\nContent-Length:#{buffer.length}\r\nContent-Type:text/plain\r\nConnection:close\r\n\r\n#{buffer}"
  rescue Errno::EPIPE
  ensure
    queue_detach connection
  end

  def deliver_500 connection, error
    buffer = "There was an internal server error -- #{error}"
puts buffer
    connection.write "HTTP/1.1 500 Bad Request\r\nContent-Length:#{buffer.length}\r\nContent-Type:text/plain\r\nConnection:close\r\n\r\n#{buffer}"
  rescue Errno::EPIPE
  ensure
    queue_detach connection
  end

  def content_type_for path
    MIME::TinyTypes.types.simple_type_for( path ) || 'application/octet-stream'
  end

  def data_for path_info
    path = File.join(@docroot,path_info)
    path if FileTest.exist?(path) and FileTest.file?(path) and File.expand_path(path).index(docroot) == 0		
  end

  def handle_processes
    if self.class.processes > 1
      @children = []
      (self.class.processes - 1).times do |thread_count|
        pid = fork()
        if pid
          @children << pid
        else
          break
        end
      end

      Thread.new { Process.waitall } if @children
    end
  end

end

SimpleWebServer.run
