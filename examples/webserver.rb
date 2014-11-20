require 'simplereactor'
require 'getoptlong'
require 'socket'

class SimpleWebServer
  
  EXE = File.basename __FILE__
  VERSION = "1.0"
  
  def self.parse_cmdline
    initialize_defaults
    
    opts = GetoptLong.new(
      [ '--help',    '-h', GetoptLong::NO_ARGUMENT],
      [ '--threads', '-t', GetoptLong::REQUIRED_ARGUMENT],
      [ '--engine',  '-e', GetoptLong::REQUIRED_ARGUMENT],
      [ '--port',    '-p', GetoptLong::REQUIRED_ARGUMENT],
      [ '--docroot', '-d', GetoptLong::REQUIRED_ARGUMENT]
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
  
-t COUNT, --threads COUNT:
  The number of threads to create of this web server. This defaults to a single
  thread.
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
      when '--threads'
        @threads = arg.to_i != 0 ? arg.to_i : @port
      end        
    end
  end
  
  def self.initialize_defaults
    @docroot = '.'
    @engine = 'nio'
    @port = 80
    @host = '127.0.0.1'
    @threads = 1
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
  
  def self.threads
    @threads
  end
  
  def self.run
    parse_cmdline
    
    SimpleReactor.use_engine @engine.to_sym
    
    webserver = SimpleWebServer.new
    
    webserver.run do |request|
      webserver.handle_response request
    end
  end

  def initialize
    @children = nil
  end
  
  def run(&block)
    Dir.chdir self.class.docroot if self.class.docroot
    
    @server = TCPServer.new self.class.host, self.class.port
    
    handle_threading
  
    SimpleReactor::Reactor.run do |reactor|
      @reactor = reactor
      @reactor.attach @server, :read do |monitor|
        connection = monitor.io.accept
        handle_request '',connection
      end
    end 
  end
  
  def handle_request buffer, connection, first=true
    buffer << connection.read_nonblock(4096)
    request = parse_request buffer
    handle_response_for request, connection if request
  rescue EOFError
    request = parse_request buffer
    handle_response_for request, connection
  rescue IO::WaitReadable
    if first
      @reactor.attach connection, :read do |monitor|
        handle_request buffer, connection, false
      end
    end
  end
  
  def handle_response_for request, connection
    path = "./#{request[:uri]}"
    if FileTest.exist?( path ) && FileTest.readable?( path )
      deliver path, connection
    else
      deliver_404 path, connection
    end
  end
  
  def parse_request buffer
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
    else
      deliver_400
    end
  end
  
  def deliver uri, connection
    data = File.read(uri)
    connection.write "HTTP/1.1 200 OK\r\nContent-Length:#{data.length}\r\nContent-Type: #{content_type_for uri,data}\r\nConnection:close\r\n\r\n#{data}"
    connection.close
  end
  
  def deliver_404 uri, connection
    buffer = "The requested resource (#{uri}) could not be found."
    connection.write "HTTP/1.1 404 Not Found\r\nContent-Length:#{buffer.length}\r\nContent-Type:text/plain\r\nConnection:close\r\n\r\n#{buffer}"
    connection.close
  end

  def deliver_400 uri, connection
    buffer = "The request was malformed and could not be completed."
    connection.write "HTTP/1.1 400 Bad Request\r\nContent-Length:#{buffer.length}\r\nContent-Type:text/plain\r\nConnection:close\r\n\r\n#{buffer}"
    connection.close
  end
 
  def content_type_for(path, data)
    "text/plain"
  end
  
  def handle_threading
    if self.class.threads > 1
      @children = []
      (self.class.threads - 1).times do |thread_count|
        pid = fork()
        if pid
          @children << pid
        else
          break
        end
      end
      
      Thread.new { waitall }
    end
  end

end

SimpleWebServer.run