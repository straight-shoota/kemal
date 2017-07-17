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
    property always_rescue = true
    property shutdown_message = true

    def scheme
      ssl ? "https" : "http"
    end

    def extra_options(&@extra_options : OptionParser ->)
    end

    def serve_static?(key)
      (h = @serve_static).is_a?(Hash) && h[key]? == true
    end

    # Create a config with default values
    def self.default
      new
    end

    # Creates a config with basic value (disabled logging, disabled serve_static, disabled shutdown_message)
    def self.base
      new.tap do |config|
        config.logging = false
        config.serve_static = false
        config.shutdown_message = false
        config.always_rescue = false
      end
    end
  end
end
