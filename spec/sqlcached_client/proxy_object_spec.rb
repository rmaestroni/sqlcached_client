require 'sqlcached_client/proxy_object'

describe SqlcachedClient::ProxyObject do
  let(:klass) do
    Class.new do
      def foo
        'bar'
      end
    end
  end

  it "forwards method calls to the proxied object" do
    f = klass.new
    p = SqlcachedClient::ProxyObject.new(f)
    expect(p.foo).to eq('bar')
  end

  describe :execute do
    it "executes the block provided in the context of the instance" do
      f = klass.new
      p = SqlcachedClient::ProxyObject.new(f)
      expect(p.execute { foo }).to eq('bar')
    end
  end

  describe :plug_method do
    it "defines a singleton method on the proxy object" do
      p = SqlcachedClient::ProxyObject.new(Object.new)
      p.plug_method(:sum) do |a, b|
        a + b
      end
      expect(p.sum(2, 3)).to eq(5)
    end
  end
end
