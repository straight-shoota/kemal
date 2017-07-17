module Kemal::FileHelpers
  # Send a file with given path and base the mime-type on the file extension
  # or default `application/octet-stream` mime_type.
  #
  #   send_file env, "./path/to/file"
  #
  # Optionally you can override the mime_type
  #
  #   send_file env, "./path/to/file", "image/jpeg"
  def self.send_file(env, path : String, mime_type : String? = nil, gzip = true)
    file_path = File.expand_path(path, Dir.current)
    mime_type ||= Kemal::Utils.mime_type(file_path)
    env.response.content_type = mime_type
    env.response.headers["X-Content-Type-Options"] = "nosniff"
    minsize = 860 # http://webmasters.stackexchange.com/questions/31750/what-is-recommended-minimum-object-size-for-gzip-performance-benefits ??
    request_headers = env.request.headers
    filesize = File.size(file_path)
    File.open(file_path) do |file|
      if env.request.method == "GET" && env.request.headers.has_key?("Range")
        next multipart(file, env)
      end
      if request_headers.includes_word?("Accept-Encoding", "gzip") && gzip && filesize > minsize && Kemal::Utils.zip_types(file_path)
        env.response.headers["Content-Encoding"] = "gzip"
        Gzip::Writer.open(env.response) do |deflate|
          IO.copy(file, deflate)
        end
      elsif request_headers.includes_word?("Accept-Encoding", "deflate") && gzip && filesize > minsize && Kemal::Utils.zip_types(file_path)
        env.response.headers["Content-Encoding"] = "deflate"
        Flate::Writer.new(env.response) do |deflate|
          IO.copy(file, deflate)
        end
      else
        env.response.content_length = filesize
        IO.copy(file, env.response)
      end
    end
    return
  end

  def send_file(env, path : String, mime_type : String? = nil)
    Kemal::FileHelpers.send_file(env, path, mime_type, config.serve_static?("gzip"))
  end

  private def self.multipart(file, env)
    # See http://httpwg.org/specs/rfc7233.html
    fileb = file.size

    range = env.request.headers["Range"]
    match = range.match(/bytes=(\d{1,})-(\d{0,})/)

    startb = 0
    endb = 0

    if match
      if match.size >= 2
        startb = match[1].to_i { 0 }
      end

      if match.size >= 3
        endb = match[2].to_i { 0 }
      end
    end

    if endb == 0
      endb = fileb
    end

    if startb < endb && endb <= fileb
      env.response.status_code = 206
      env.response.content_length = endb - startb
      env.response.headers["Accept-Ranges"] = "bytes"
      env.response.headers["Content-Range"] = "bytes #{startb}-#{endb - 1}/#{fileb}" # MUST

      if startb > 1024
        skipped = 0
        # file.skip only accepts values less or equal to 1024 (buffer size, undocumented)
        until skipped + 1024 > startb
          file.skip(1024)
          skipped += 1024
        end
        if skipped - startb > 0
          file.skip(skipped - startb)
        end
      else
        file.skip(startb)
      end

      IO.copy(file, env.response, endb - startb)
    else
      env.response.content_length = fileb
      env.response.status_code = 200 # Range not satisfable, see 4.4 Note
      IO.copy(file, env.response)
    end
  end

  # Send a file with given data and default `application/octet-stream` mime_type.
  #
  #   send_file env, data_slice
  #
  # Optionally you can override the mime_type
  #
  #   send_file env, data_slice, "image/jpeg"
  def send_file(env, data : Slice(UInt8), mime_type : String? = nil)
    mime_type ||= "application/octet-stream"
    env.response.content_type = mime_type
    env.response.content_length = data.bytesize
    env.response.write data
  end

  # Configures an `HTTP::Server::Response` to compress the response
  # output, either using gzip or deflate, depending on the `Accept-Encoding` request header.
  # It's disabled by default.
  def gzip(status : Bool = false)
    add_handler HTTP::CompressHandler.new if status
  end
end
