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

  describe :store_attachments do
    pending
  end
end
