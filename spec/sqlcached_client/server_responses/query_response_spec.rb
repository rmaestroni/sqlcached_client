require 'sqlcached_client/server_responses/query_response'

describe SqlcachedClient::ServerResponses::QueryResponse do
  let(:described_class) { SqlcachedClient::ServerResponses::QueryResponse }

  describe :entities do
    context "if body is an array" do
      it "parses each item recoursively" do
        query_response = described_class.new([[1, 2, [3, 4]], 5])
        expect(query_response.entities).to eq(
          [[1, 2, [3, 4]], 5])
      end
    end

    context "if body is an hash" do
      it "returns the value corresponding to the key 'resultset'" do
        query_response = described_class.new({ 'resultset' => 1 })
        expect(query_response.entities).to eq(1)
      end

      context "if key 'resultset' is not present" do
        it "is nil" do
          query_response = described_class.new({ foo: 'bar' })
          expect(query_response.entities).to be_nil
        end
      end

      context "if resultset is a string" do
        it "is parsed as json" do
          query_response = described_class.new({
            'resultset' => "{ \"foo\": \"bar\", \"baz\": 1 }"
          })
          expect(query_response.entities).to eq({
            "foo" => "bar", "baz" => 1 })
        end
      end
    end
  end

  describe :attachments do
    context "when body is an Hash" do
      it "is body.attachments" do
        query_response = described_class.new({ 'attachments' => 'foo' })
        expect(query_response.attachments).to eq('foo')
      end
    end

    context "when body is not an Hash" do
      it "is nil" do
        query_response = described_class.new(['foo', 'bar'])
        expect(query_response.attachments).to be_nil
      end
    end
  end

  describe :is_array? do
    context "when entities is an Array" do
      it "is true" do
        query_response = described_class.new(['foo'])
        expect(query_response.is_array?).to eq(true)
      end
    end

    context "when entities is not an Array" do
      it "is false" do
        query_response = described_class.new({})
        expect(query_response.is_array?).to eq(false)
      end
    end
  end

  describe :flatten! do
    it "flattens the entities in place" do
      query_response = described_class.new([[1, [2]], [3]])
      query_response.flatten!
      expect(query_response.entities).to eq([1, 2, 3])
    end
  end
end
