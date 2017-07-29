require "./helpers/*"
require "./base/*"

# Kemal Base
# The DSL currently consists of
# - get post put patch delete options
# - WebSocket(ws)
# - before_*
# - error
class Kemal::Base
  include FileHelpers
  include Templates
  include Macros
  include Base::DSL
  include Base::Builder

  # :nodoc:
  getter! route_handler
  # :nodoc:
  getter! filter_handler

  getter handlers = [] of HTTP::Handler
  getter websocket_handlers = [] of HTTP::WebSocketHandler
  getter error_handlers = {} of Int32 => HTTP::Server::Context, Exception -> String

  getter config : Config

  property! logger : Kemal::BaseLogHandler
  property! server : HTTP::Server
  property? running = false

  def initialize(@config = Config.base)
    @filter_handler = Kemal::FilterHandler.new(self)
    @route_handler = Kemal::RouteHandler.new(self)
    initialize_defaults
  end

  def run(port = nil)
    run(port) { }
  end

  # Overload of self.run to allow just a block
  def run(&block)
    run nil, &block
  end

  # The command to run a `Kemal` application.
  # The port can be given to `#run` but is optional.
  # If not given Kemal will use `Kemal::Config#port`
  def run(port = nil, &block)
    setup

    prepare_for_server_start

    start_server port, &block
  end

  def self.run(port = nil, &block)
    new.tap do |app|
      Kemal::CLI.new(app.config)

      app.run(port, &block)
    end
  end

  def self.run(port = nil)
    new.tap do |app|
      Kemal::CLI.new(app.config)

      app.run(port)
    end
  end

  # DEPRECATED: This method should be replaced with `#running?`
  def running
    running?
  end

  private def prepare_for_server_start
    unless @config.env == "test"
      Signal::INT.trap do
        log "Kemal is going to take a rest!" if @config.shutdown_message
        stop
        exit
      end
    end
  end

  private def start_server(port, &block)
    @server = server = HTTP::Server.new(@config.host_binding, port || @config.port, @handlers)
    {% if !flag?(:without_openssl) %}
    server.tls = config.ssl
    {% end %}

    server.bind unless @config.env == "test"
    @running = true

    yield self

    server.listen unless @config.env == "test"
  end

  def stop
    if @running
      if server = @server
        server.close
        @running = false
      else
        raise "server is not set. Please use run to set the server."
      end
    else
      raise "Kemal is already stopped."
    end
  end

  def log(message)
    logger.write "#{message}\n"
  end
end

require "./main"
