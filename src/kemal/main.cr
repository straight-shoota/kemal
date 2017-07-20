require "http"
require "json"
require "uri"
require "tempfile"

module Kemal
  def self.application
    @@application ||= Kemal::Application.new
  end

  def self.config
    application.config
  end

  # Overload of self.run with the default startup logging
  def self.run(port = nil)
    run port do
      log "[#{config.env}] Kemal is ready to lead at #{config.scheme}://#{config.host_binding}:#{config.port}"
    end
  end

  # Overload of self.run to allow just a block
  def self.run(&block)
    run nil, &block
  end

  # The command to run a `Kemal` application.
  # The port can be given to `#run` but is optional.
  # If not given Kemal will use `Kemal::Config#port`
  def self.run(port = nil, &block)
    Kemal::CLI.new(config)

    application.run(port, &block)
  end

  def self.stop
    application.stop
  end
end

require "./application"
require "./base_log_handler"
require "./cli"
require "./common_exception_handler"
require "./common_log_handler"
require "./config"
require "./exceptions"
require "./file_upload"
require "./filter_handler"
require "./handler"
require "./init_handler"
require "./null_log_handler"
require "./param_parser"
require "./response"
require "./route"
require "./route_handler"
require "./ssl"
require "./static_file_handler"
require "./websocket_handler"
require "./ext/*"
require "./helpers/*"
