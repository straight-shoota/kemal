module Kemal
  # Kemal::Config stores all the configuration options for a Kemal application.
  # It's a singleton and you can access it like.
  #
  #   Kemal.config
  #
  class Config
    # :nodoc:
    DEFAULT_SERVE_STATIC = {"dir_listing" => false, "gzip" => true}

    {% if flag?(:without_openssl) %}
    property ssl : Bool?
    {% else %}
    property ssl : OpenSSL::SSL::Context::Server?
    {% end %}

    property extra_options
    getter custom_handler_position

    property host_binding = "0.0.0.0"
    property port = 3000
    property env = "development"
    property serve_static : Hash(String, Bool) | Bool = DEFAULT_SERVE_STATIC
    property public_folder = "./public"
    property logging = true
    property! logger : Kemal::BaseLogHandler
    property error_handler = Kemal::CommonExceptionHandler.new
    property always_rescue = true
    property router_included = false
    property default_handlers_setup = false
    property shutdown_message = true

    def scheme
      ssl ? "https" : "http"
    end

    def extra_options(&@extra_options : OptionParser ->)
    end
  end
end
