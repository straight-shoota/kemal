require "radix"

module Kemal
  # Kemal::RouteHandler is the main handler which handles all the HTTP requests. Routing, parsing, rendering e.g
  # are done in this handler.
  class RouteHandler
    include HTTP::Handler

    property tree

    getter app : Kemal::Base

    def initialize(@app)
      @tree = Radix::Tree(Route).new
    end

    def call(context)
      process_request(context)
    end

    # Adds a given route to routing tree. As an exception each `GET` route additionaly defines
    # a corresponding `HEAD` route.
    def add_route(method, path, &handler : HTTP::Server::Context -> _)
      add_to_radix_tree method, path, Route.new(method, path, &handler)
      add_to_radix_tree("HEAD", path, Route.new("HEAD", path) { |ctx| "" }) if method == "GET"
    end

    # Check if a route is defined and returns the lookup
    def lookup_route(verb, path)
      @tree.find radix_path(verb, path)
    end

    def lookup_route(request)
      lookup_route request.override_method.as(String), request.path
    end

    def route_defined?(request)
      lookup_route(request).found?
    end

    # Processes the route if it's a match. Otherwise renders 404.
    private def process_request(context)
      raise Kemal::Exceptions::RouteNotFound.new(context) unless route_defined?(context.request)
      route = lookup_route(context.request).payload.as(Route)
      content = route.handler.call(context)
    ensure
      remove_tmpfiles(context)
      if app.error_handlers.has_key?(context.response.status_code)
        raise Kemal::Exceptions::CustomException.new(context)
      end
      context.response.print(content)
      context
    end

    private def remove_tmpfiles(context)
      context.params.files.each do |field, file|
        File.delete(file.tmpfile.path) if ::File.exists?(file.tmpfile.path)
      end
    end

    private def radix_path(method : String, path)
      "/#{method.downcase}#{path}"
    end

    private def add_to_radix_tree(method, path, route)
      node = radix_path method, path
      @tree.add node, route
    end
  end
end
