require 'uri'
require 'net/http'
require 'json'
require 'sqlcached_client/server_responses/query_response'

module SqlcachedClient
  class Server
    attr_reader :host, :port

    # @param config [Hash] something like { host: 'localhost', port: 8081 }
    def initialize(config)
      @host = config[:host]
      @port = config[:port]
    end

    # @return [ServerResponses::QueryResponse]
    def run_query(session, http_req_body)
      req = Net::HTTP::Post.new(data_batch_url)
      req.set_content_type('application/json')
      req.body = http_req_body.to_json
      resp = session.request(req)
      resp_body =
        if (resp['Content-Type'] || '') =~ /application\/json/
          JSON.parse(resp.body)
        else
          resp.body
        end
      if 200 == resp.code.to_i
        ServerResponses::QueryResponse.new(resp_body)
      else
        raise "Got HTTP response #{resp.code} from server - #{resp_body.inspect}"
      end
    end


    def store_attachments(session, http_req_body)
      req = Net::HTTP::Post.new(store_attachments_url)
      req.set_content_type('application/json')
      req.body = http_req_body.to_json
      resp = session.request(req)
      201 == resp.code.to_i || raise("Failed to save attachments - server answered with #{resp.body.inspect}")
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
    def build_tree_request(tree, root_parameters, attachments = nil)
      h = { tree: tree, root_parameters: root_parameters }
      if !attachments.nil?
        h[:attachments] = attachments.map(&:to_query_format)
      end
      h
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


    def build_store_attachments_request(entities, attachments)
      {
        resultset: entities,
        attachments: attachments
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
      url.path = '/data-batch'
      url
    end

    def store_attachments_url
      url = server_url
      url.path = '/resultset-attachments'
      url
    end
  end
end
