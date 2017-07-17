require "http"
require "json"
require "uri"
require "tempfile"
require "./kemal/base"
require "./kemal/application"
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
