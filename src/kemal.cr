require "http"
require "json"
require "uri"
require "tempfile"
require "./kemal/base"
require "./kemal/base_log_handler"
require "./kemal/cli"
require "./kemal/common_exception_handler"
require "./kemal/common_log_handler"
require "./kemal/config"
require "./kemal/exceptions"
require "./kemal/file_upload"
require "./kemal/filter_handler"
require "./kemal/handler"
require "./kemal/init_handler"
require "./kemal/null_log_handler"
require "./kemal/param_parser"
require "./kemal/response"
require "./kemal/route"
require "./kemal/route_handler"
require "./kemal/ssl"
require "./kemal/static_file_handler"
require "./kemal/websocket_handler"
require "./kemal/ext/*"
require "./kemal/helpers/*"

module Kemal
  # Overload of self.run with the default startup logging
  def self.run(port = nil)
    self.run port do
      log "[#{config.env}] Kemal is ready to lead at #{config.scheme}://#{config.host_binding}:#{config.port}"
    end
  end

  # Overload of self.run to allow just a block
  def self.run(&block)
    self.run nil, &block
  end

  # The command to run a `Kemal` application.
  # The port can be given to `#run` but is optional.
  # If not given Kemal will use `Kemal::Config#port`
  def self.run(port = nil, &block)
    Kemal::CLI.new
    config = Kemal::Config.new
    application = Kemal::Base.new(config)
    config.port = port if port
    application.setup

    application.server = HTTP::Server.new(config.host_binding, config.port, application.handlers)
    {% if !flag?(:without_openssl) %}
    application.server.tls = config.ssl
    {% end %}

    unless application.error_handlers.has_key?(404)
      application.error 404 do |env|
        render_404
      end
    end

    # Test environment doesn't need to have signal trap, built-in images, and logging.
    unless config.env == "test"
      Signal::INT.trap do
        log "Kemal is going to take a rest!" if config.shutdown_message
        Kemal.stop
        exit
      end

      # This route serves the built-in images for not_found and exceptions.
      application.get "/__kemal__/:image" do |env|
        image = env.params.url["image"]
        file_path = File.expand_path("lib/kemal/images/#{image}", Dir.current)
        if File.exists? file_path
          send_file env, file_path
        else
          halt env, 404
        end
      end
    end

    application.running = true
    yield config
    application.server.listen if config.env != "test"
  end

  def self.stop
    if application.running
      if application.server
        application.server.close
        application.running = false
      else
        raise "Kemal.application.server is not set. Please use Kemal.run to set the server."
      end
    else
      raise "Kemal is already stopped."
    end
  end
end
