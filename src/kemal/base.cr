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
  getter route_handler = Kemal::RouteHandler.new
  # :nodoc:
  getter filter_handler = Kemal::FilterHandler.new

  getter handlers = [] of HTTP::Handler
  getter websocket_handlers = [] of HTTP::WebSocketHandler
  getter error_handlers = {} of Int32 => HTTP::Server::Context, Exception -> String

  getter config : Config

  property! logger : Kemal::BaseLogHandler
  property! server : HTTP::Server
  property? running = false

  def initialize(@config = Config.base)
    initialize_defaults
  end

  # Overload of self.run with the default startup logging
  def run(port = nil)
    run port do
      log "[#{config.env}] Kemal is ready to lead at #{config.scheme}://#{config.host_binding}:#{config.port}"
    end
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

    start_server &block
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

  private def start_server(&block)
    @server = server = HTTP::Server.new(@config.host_binding, @config.port, @handlers)
    {% if !flag?(:without_openssl) %}
    server.tls = config.ssl
    {% end %}

    server.bind
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
