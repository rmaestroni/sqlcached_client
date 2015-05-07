require 'sqlcached_client/entity'
require 'sqlcached_client/server'

describe SqlcachedClient::Entity do

  describe :initialize do
    it "should record the attribute names" do
      e = SqlcachedClient::Entity.new({ foo: 'bar', baz: 'biz' })
      expect(e.attribute_names).to eq([:foo, :baz])
    end
  end


  describe :entity_name do
    it "should set query_id" do
      entity_class = Class.new(SqlcachedClient::Entity) do
        entity_name("foo")
      end
      expect(entity_class.query_id).to eq("foo")
    end
  end


  describe :query do
    context "if a parameter is provided" do
      it "should set @query and strip spaces" do
        entity_class = Class.new(SqlcachedClient::Entity) do
          query("  foo \n  ")
        end
        expect(entity_class.instance_variable_get(:@query)).to eq("foo")
      end
    end

    context "if no parameter is provided" do
      it "should return the value previously stored" do
        entity_class = Class.new(SqlcachedClient::Entity) do
          query("  foo \n  ")
        end
        expect(entity_class.query).to eq("foo")
      end
    end
  end


  describe :server do
    context "if a parameter is provided" do
      it "should set @server" do
        entity_class = Class.new(SqlcachedClient::Entity) do
          server("foo")
        end
        expect(entity_class.instance_variable_get(:@server)).to eq("foo")
      end

      context "if the parameter is an hash" do
        it "should instantiate a new Server" do
          entity_class = Class.new(SqlcachedClient::Entity) do
            server(foo: "bar")
          end
          expect(entity_class.server).to be_instance_of(SqlcachedClient::Server)
        end
      end
    end

    context "if no parameter is provided" do
      it "should return the value previously stored" do
        entity_class = Class.new(SqlcachedClient::Entity) do
          server("foo")
        end
        expect(entity_class.server).to eq("foo")
      end

      context "if no server was configured for the class" do
        it "should use the value from the first ancestor" do
          entity_class0 = Class.new(SqlcachedClient::Entity) do
            server("foo")
          end
          entity_class1 = Class.new(entity_class0)
          expect(entity_class1.server).to eq("foo")
        end
      end
    end
  end


  describe :where do
    let(:entity_class) do
      Class.new(SqlcachedClient::Entity) do
        entity_name 'foo'
        query 'bar'
      end
    end

    context "if dry_run" do
      it "should return the request that would be sent to the server" do
        entity_class.server(double(format_request: "this is the request"))
        expect(entity_class.server).to receive(:format_request).with("foo", "bar", { baz: "biz" })
        expect(entity_class.where({ baz: "biz" }, true)).to eq("this is the request")
      end
    end

    context "if not dry_run" do
      it "should create a new ResultSet" do
        entity_class.server(double(
          format_request: "this is the request",
          build_request_body: "request body",
          run_query: [[{ key: "value" }], 2, 3]
        ))
        expect(entity_class.server).to receive(:format_request).with(
          "foo", "bar", { baz: "biz" })
        expect(entity_class.server).to receive(:build_request_body).with(
          ["this is the request"])
        expect(entity_class.server).to receive(:run_query).with("request body")
        expect(entity_class.where({ baz: "biz" })).to be_instance_of(
          SqlcachedClient::Resultset)
      end
    end
  end


  describe :has_many do
    pending
  end


  describe :has_one do
    pending
  end


  describe :get_association_requests do
    pending
  end


  describe :set_associations_data do
    pending
  end


  describe :get_associations do
    pending
  end


  describe :build_associations do
    pending
  end


  describe :to_h do
    pending
  end
end
