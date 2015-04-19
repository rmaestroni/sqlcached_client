require 'uri'
require 'net/http'
require 'json'

module SqlcachedClient
  class Server
    attr_reader :host, :port

    def initialize(config)
      @host = config[:host]
      @port = config[:port]
    end

    def run_query(query_id, query, params)
      url = server_url
      Net::HTTP.start(url.host, url.port) do |http|
        get_resp = get_db_data(http, query_id, params)
        if 200 == get_resp[:status]
          get_resp[:body]
        elsif 404 == get_resp[:status]
          create_query_template(http, query_id, query)
          # reiterate get_db_data request
          get_resp = get_db_data(http, query_id, params)
          if 200 == get_resp[:status]
            get_resp[:body]
          else
            raise "Got http response #{get_resp[:status]} from server - #{get_resp[:body].inspect}"
          end
        else
          raise "Got http response #{get_resp[:status]} from server - #{get_resp[:body].inspect}"
        end
      end
    end

    def get_db_data(http, query_id, params)
      d_url = data_url(query_id, params)
      resp = http.request(Net::HTTP::Get.new(d_url))
      if 'application/json' == resp['Content-Type']
        resp_body = JSON.parse(resp.body)
      else
        resp_body = resp.body
      end
      { status: resp.code.to_i, body: resp_body }
    end

    def create_query_template(http, query_id, query_template)
      req = Net::HTTP::Post.new(query_template_url)
      req.set_form_data(id: query_id, query: query_template)
      resp = http.request(req)
      if 'application/json' == resp['Content-Type']
        resp_body = JSON.parse(resp.body)
      else
        resp_body = resp.body
      end
      { status: resp.code.to_i, body: resp_body }
    end

  private

    def server_url
      URI("http://#{host}:#{port}")
    end

    def data_url(query_id, params)
      url = server_url
      url.path = "/data/#{query_id}"
      query_params = params.map { |k, v| ["query_params[#{k}]", v] }
      url.query = URI.encode_www_form(query_params.to_h)
      url
    end

    def query_template_url
      url = server_url
      url.path = "/queries"
      url
    end
  end
end
