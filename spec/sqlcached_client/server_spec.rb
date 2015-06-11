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


  describe :parse_response_body do
    context "if body is an array" do
      it "should parse each item recoursively" do
        expect(server.parse_response_body([[1, 2, [3, 4]], 5])).to eq(
          [[1, 2, [3, 4]], 5])
      end
    end

    context "if body is an hash" do
      it "should return the value corresponding to the key 'resultset'" do
        expect(server.parse_response_body({ 'resultset' => 1 })).to eq(1)
      end

      context "if key 'resultset' is not present" do
        it "should be nil" do
          expect(server.parse_response_body({ foo: 'bar' })).to be_nil
        end
      end

      context "if resultset is a string" do
        it "should be parsed as json" do
          expect(server.parse_response_body({
            'resultset' => "{ \"foo\": \"bar\", \"baz\": 1 }" })).to eq({
            "foo" => "bar", "baz" => 1 })
        end
      end
    end
  end
end
