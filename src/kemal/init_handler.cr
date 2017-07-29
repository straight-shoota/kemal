module Kemal
  # Kemal::InitHandler is the first handler thus initializes the context with default values.
  # Such as *Content-Type*, *X-Powered-By* headers.
  class InitHandler
    include HTTP::Handler

    getter app : Kemal::Base

    def initialize(@app)
    end

    def call(context)
      context.response.headers.add "X-Powered-By", "Kemal"
      context.response.content_type = "text/html" unless context.response.headers.has_key?("Content-Type")
      context.initialize_url_params(app)
      call_next context
    end
  end
end
