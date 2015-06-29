require 'uri'
require 'net/http'
require 'json'

module SqlcachedClient
  class Server
    attr_reader :host, :port

    # @param config [Hash] something like { host: 'localhost', port: 8081 }
    def initialize(config)
      @host = config[:host]
      @port = config[:port]
    end


    def run_query(session, http_req_body)
      req = Net::HTTP::Post.new(data_batch_url)
      req.set_content_type('application/json')
      req.body = http_req_body.to_json
      resp = session.request(req)
      if (resp['Content-Type'] || '') =~ /application\/json/
        resp_body = parse_response_body(JSON.parse(resp.body))
      else
        resp_body = resp.body
      end
      if 200 == resp.code.to_i
        resp_body
      else
        raise "Got HTTP response #{resp.code} from server - #{resp_body.inspect}"
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

    # Builds a 'standard' request body
    # @param ary [Array]
    # @return [Hash]
    def build_request(ary)
      { batch: ary }
    end

    # Builds a request body suitable for a 'tree' request
    # @param tree [Hash]
    # @param root_parameters [Array] a vector of actual condition parameters
    #   for the root query
    def build_tree_request(tree, root_parameters)
      { tree: tree, root_parameters: root_parameters }
    end

    # Formats the parameters passed in the way the server expects
    # @param query_id [String] unique identifier for this query
    # @param query_template [String] the sql template
    # @param params [Hash] the parameter to fill the template
    # @param cache [Integer] number of seconds the data should be cached
    # @return [Hash]
    def build_request_item(query_id, query_template, params, cache)
      {
        query_id: query_id,
        query_template: query_template,
        query_params: params,
        cache: cache
      }
    end

    # @return [Net::HTTP] an http session on the server
    def get_session
      url = server_url
      Net::HTTP.start(url.host, url.port)
    end

    # Starts an http session yielding the block passed. Closes the connession
    # when the block returns.
    # @return the value returned by the block
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
