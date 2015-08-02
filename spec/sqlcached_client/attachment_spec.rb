require 'sqlcached_client/attachment'

describe SqlcachedClient::Attachment do

  let(:described_class) { SqlcachedClient::Attachment }

  describe :initialize do
    it "accepts name, conditions and content" do
      attachment = described_class.new('name', { 'foo' => 'bar'}, 'content')
      expect(attachment.name).to eq('name')
      expect(attachment.conditions).to eq({ 'foo' => 'bar' })
      expect(attachment.content).to eq('content')
    end
  end

  describe :variables do
    it "returns the variables added to the class" do
      attachment = described_class.new(nil, {}, nil)
      allow(described_class).to receive(:variables).and_return('foo')
      expect(attachment.variables).to eq('foo')
    end
  end

  describe :to_query_format do
    it "is an hash with name and condition values" do
      attachment = described_class.new('foo', { v1: 'bar', v2: 'baz'}, nil)
      allow(attachment).to receive(:variables).and_return([
        double(name: 'v1'), double(name: 'v2')
      ])
      expect(attachment.to_query_format).to eq({
        name: 'foo',
        condition_values: {
          'v1' => 'bar', 'v2' => 'baz'
        }
      })
    end
  end

  describe :to_save_format do
    it "is an hash with name, attachment and conditions" do
      attachment = described_class.new('foo', { v1: 'bar', v2: 'baz'},
        'content')
      allow(attachment).to receive(:variables).and_return([
        double(name: 'v1', predicate: '='), double(name: 'v2', predicate: '<=')
      ])
      expect(attachment.to_save_format).to eq({
        name: 'foo',
        attachment: 'content',
        conditions: ['v1 = bar', 'v2 <= baz']
      })
    end
  end

  describe :add_variable do
    it "adds a new variable in the class list" do
      described_class.add_variable('foo', '=')
      v = described_class.variables.first
      expect(v.name).to eq('foo')
      expect(v.predicate).to eq('=')
    end

    context "if predicate symbol is not allowed" do
      it "raises an exception" do
        expect { described_class.add_variable('foo', 'X') }.to raise_exception
      end
    end
  end
end
