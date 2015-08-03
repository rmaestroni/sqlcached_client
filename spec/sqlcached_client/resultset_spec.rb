require 'sqlcached_client/resultset'

describe SqlcachedClient::Resultset do

  describe :initialize do

    it "should set count" do
      r = SqlcachedClient::Resultset.new(Object, [Object.new] * 3)
      expect(r.count).to eq(3)
    end

    context "when passed entities are hashes" do
      it "should map them to instances of the entity class provided" do
        r = SqlcachedClient::Resultset.new(SqlcachedClient::Entity,
          [{ foo: 'bar' }] * 3)
        expect(r.entities[0]).to be_instance_of(SqlcachedClient::Entity)
      end
    end

    context "when passing entities that are instances of the class" do
      it "should set them without do anything" do
        entities = [Object.new] * 3
        r = SqlcachedClient::Resultset.new(Object, entities)
        expect(r.entities).to eq(entities)
      end
    end
  end

  describe :build_associations do
    pending
  end

  describe :[] do
    it "should be entities[i]" do
      entities = [Object.new] * 3
      r = SqlcachedClient::Resultset.new(Object, entities)
      3.times { |i| expect(r[i]).to eq(entities[i]) }
    end
  end

  describe :set_entities_attachments do
    let(:resultset) { SqlcachedClient::Resultset.new(nil, nil) }

    let(:entities) do
      [double(:attach1=)]
    end

    let(:attachment) { double(:content=, name: 'attach1') }

    it "sets each attachment to the corresponding entity and saves the content" do
      expect(entities.first).to receive(:attach1=).with(attachment)
      expect(attachment).to receive(:content=).with('content')
      resultset.set_entities_attachments(entities, [attachment], ['content'])
    end
  end

  describe :store_attachments do
    let(:resultset) { SqlcachedClient::Resultset.new(nil, nil) }

    let(:entities) do
      [
        double(att1: double(to_save_format: 'value a'), attributes: 'attrs a'),
        double(att1: double(to_save_format: 'value b'), attributes: 'attrs b')
      ]
    end

    let(:server) { double }

    it "calls server.store_attachments" do
      expect(server).to receive(:build_store_attachments_request).with(
        ['attrs a', 'attrs b'], ['value a', 'value b']
      ).and_return('attachment request')
      expect(server).to receive(:store_attachments).with('session',
        'attachment request')
      allow(resultset).to receive(:entities).and_return(entities)
      resultset.store_attachments(:att1, server, 'session')
    end
  end
end
