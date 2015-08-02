require 'sqlcached_client/server'

describe SqlcachedClient::Server do

  let(:server) { SqlcachedClient::Server.new({}) }

  describe :initialize do
    it "should set host and port" do
      server = SqlcachedClient::Server.new(host: "localhost", port: 80)
      expect(server.host).to eq("localhost")
      expect(server.port).to eq(80)
    end
  end

  describe :build_request do
    it "should put the passed value into an hash" do
      expect(server.build_request("foo")).to eq({ batch: "foo" })
    end
  end

  describe :build_tree_request do
    it "should be an Hash with 'tree' and 'root_parameters' keys" do
      expect(server.build_tree_request('tree', 'root')).to eq({
        tree: 'tree', root_parameters: 'root'
      })
    end
  end

  describe :build_request_item do
    it "should be an hash with id, template, params keys" do
      expect(server.build_request_item("foo", "bar", "baz", "cache")).to eq({
        query_id: "foo",
        query_template: "bar",
        query_params: "baz",
        cache: "cache"
      })
    end
  end

  describe :build_store_attachments_request do
    it "contains keys resultset and attachments" do
      expect(server.build_store_attachments_request('e', 'a')).to eq({
        resultset: 'e', attachments: 'a'
      })
    end
  end
end
