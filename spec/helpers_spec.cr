require "./spec_helper"

private class CustomTestHandler < Kemal::Handler
  def call(env)
    env.response << "Kemal"
    call_next env
  end
end

describe "Macros" do
  describe "#add_handler" do
    it "adds a custom handler" do
      app = Kemal::Application.new
      app.add_handler CustomTestHandler.new
      app.setup
      app.handlers.size.should eq 7
    end
  end

  describe "#logging" do
    it "sets logging status" do
      logging false
      Kemal.config.logging.should eq false
    end

    it "sets a custom logger" do
      logger CustomLogHandler.new
      Kemal.application.logger.should be_a(CustomLogHandler)
    end
  end

  describe "#halt" do
    it "can break block with halt macro" do
      app = Kemal::Base.new
      app.get "/non-breaking" do |env|
        "hello"
        "world"
      end
      request = HTTP::Request.new("GET", "/non-breaking")
      client_response = call_request_on_app(app, request)
      client_response.status_code.should eq(200)
      client_response.body.should eq("world")

      app.get "/breaking" do |env|
        Kemal::Macros.halt env, 404, "hello"
        "world"
      end
      request = HTTP::Request.new("GET", "/breaking")
      client_response = call_request_on_app(app, request)
      client_response.status_code.should eq(404)
      client_response.body.should eq("hello")
    end

    it "can break block with halt macro using default values" do
      app = Kemal::Base.new
      app.get "/" do |env|
        Kemal::Macros.halt env
        "world"
      end
      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(app, request)
      client_response.status_code.should eq(200)
      client_response.body.should eq("")
    end
  end

  describe "#headers" do
    it "can add headers" do
      app = Kemal::Base.new
      app.get "/headers" do |env|
        env.response.headers.add "Content-Type", "image/png"
        app.headers env, {
          "Access-Control-Allow-Origin" => "*",
          "Content-Type"                => "text/plain",
        }
      end
      request = HTTP::Request.new("GET", "/headers")
      response = call_request_on_app(app, request)
      response.headers["Access-Control-Allow-Origin"].should eq("*")
      response.headers["Content-Type"].should eq("text/plain")
    end
  end

  describe "#send_file" do
    it "sends file with given path and default mime-type" do
      app = Kemal::Base.new
      app.get "/" do |env|
        app.send_file env, "./spec/asset/hello.ecr"
      end

      request = HTTP::Request.new("GET", "/")
      response = call_request_on_app(app, request)
      response.status_code.should eq(200)
      response.headers["Content-Type"].should eq("application/octet-stream")
      response.headers["Content-Length"].should eq("18")
    end

    it "sends file with given path and given mime-type" do
      app = Kemal::Base.new
      app.get "/" do |env|
        app.send_file env, "./spec/asset/hello.ecr", "image/jpeg"
      end

      request = HTTP::Request.new("GET", "/")
      response = call_request_on_app(app, request)
      response.status_code.should eq(200)
      response.headers["Content-Type"].should eq("image/jpeg")
      response.headers["Content-Length"].should eq("18")
    end

    it "sends file with binary stream" do
      app = Kemal::Base.new
      app.get "/" do |env|
        app.send_file env, "Serdar".to_slice
      end

      request = HTTP::Request.new("GET", "/")
      response = call_request_on_app(app, request)
      response.status_code.should eq(200)
      response.headers["Content-Type"].should eq("application/octet-stream")
      response.headers["Content-Length"].should eq("6")
    end
  end
end
