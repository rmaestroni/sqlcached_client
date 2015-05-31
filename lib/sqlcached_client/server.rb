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


    def run_query(session, http_req_body)
      req = Net::HTTP::Post.new(data_batch_url)
      req.set_content_type('application/json')
      req.body = http_req_body.to_json
      resp = session.request(req)
      if 'application/json' == resp['Content-Type']
        resp_body = parse_response_body(JSON.parse(resp.body))
      else
        resp_body = resp.body
      end
      if 200 == resp.code.to_i
        resp_body
      else
        raise "Got http response #{resp.code} from server - #{resp_body.inspect}"
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


    def format_request(query_id, query_template, params, cache)
      {
        queryId: query_id,
        queryTemplate: query_template,
        queryParams: params,
        cache: cache
      }
    end


    def get_session
      url = server_url
      Net::HTTP.start(url.host, url.port)
    end


    def session
      s = get_session
      ret_value = yield(self, s) if block_given?
      s.finish
      ret_value
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
