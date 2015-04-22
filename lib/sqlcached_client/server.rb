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


    def self.log_request(url)
      @logged_urls ||= []
      @logged_urls << url
    end


    def self.logged_requests
      @logged_urls
    end


    def run_query(http_req_body)
      url = server_url
      Net::HTTP.start(url.host, url.port) do |http|
        req = Net::HTTP::Post.new(data_batch_url)
        req.set_content_type('application/json')
        req.body = http_req_body.to_json
        resp = http.request(req)
        if 'application/json' == resp['Content-Type']
          resp_body = parse_response_body(JSON.parse(resp.body))
        else
          resp_body = resp.body
        end
        if 200 == resp.code.to_i
          resp_body
        else
          raise "Got http response #{resp.code} from server - #{resp_body}"
        end
      end
    end


    def parse_response_body(body)
      if body.is_a?(Array)
        body.map { |item| parse_response_body(item) }
      elsif body.is_a?(Hash)
        if (resultset = body['resultset']).is_a?(String)
          JSON.parse(resultset)
        else
          resultset
        end
      else
        body
      end
    end


    def build_request_body(ary)
      { batch: ary }
    end


    def format_request(query_id, query_template, params)
      {
        queryId: query_id,
        queryTemplate: query_template,
        queryParams: params
      }
    end

  private

    def server_url
      URI("http://#{host}:#{port}")
    end

    def data_batch_url
      url = server_url
      url.path = "/data-batch"
      url
    end
  end
end
