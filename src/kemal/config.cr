module Kemal
  # Kemal::Config stores all the configuration options for a Kemal application.
  # It's a singleton and you can access it like.
  #
  #   Kemal.config
  #
  class Config
    {% if flag?(:without_openssl) %}
    property ssl : Bool?
    {% else %}
    property ssl : OpenSSL::SSL::Context::Server?
    {% end %}

    property host_binding = "0.0.0.0"
    property port = 3000
    property env = "development"
    property serve_static : Hash(String, Bool) | Bool = {"dir_listing" => false, "gzip" => true}
    property public_folder = "./public"
    property logging = true
    property always_rescue = true
    property shutdown_message = true
    property extra_options : (OptionParser ->)?

    # Creates a config with default values.
    def initialize(
                   @host_binding = "0.0.0.0",
                   @port = 3000,
                   @env = "development",
                   @serve_static = {"dir_listing" => false, "gzip" => true},
                   @public_folder = "./public",
                   @logging = true,
                   @always_rescue = true,
                   @shutdown_message = true,
                   @extra_options = nil)
    end

    def scheme
      ssl ? "https" : "http"
    end

    def extra_options(&@extra_options : OptionParser ->)
    end

    def serve_static?(key)
      (h = @serve_static).is_a?(Hash) && h[key]? == true
    end

    # Creates a config with basic value (disabled logging, disabled serve_static, disabled shutdown_message).
    def self.base
      new(
        logging: false,
        serve_static: false,
        shutdown_message: false,
        always_rescue: false,
      )
    end
  end
end
