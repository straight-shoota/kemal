class Kemal::Application < Kemal::Base
  def initialize(config = Config.new)
    super(config)
  end

  private def prepare_for_server_start
    super

    unless error_handlers.has_key?(404)
      error 404 do |env|
        render_404
      end
    end

    # Test environment doesn't need to have signal trap, built-in images, and logging.
    unless @config.env == "test"
      # This route serves the built-in images for not_found and exceptions.
      get "/__kemal__/:image" do |env|
        image = env.params.url["image"]
        file_path = File.expand_path("lib/kemal/images/#{image}", Dir.current)
        if File.exists? file_path
          send_file env, file_path
        else
          halt env, 404
        end
      end
    end
  end
end
