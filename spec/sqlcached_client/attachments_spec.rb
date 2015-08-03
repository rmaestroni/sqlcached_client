require 'sqlcached_client/attachments'

describe SqlcachedClient::Attachments do
  let(:klass) do
    Class.new do
      include SqlcachedClient::Attachments

      has_attachment :foo do
      end
    end
  end

  context "after including the module" do
    it "add methods 'has_attachment' and 'build_attachments' to the class" do
      expect(klass.respond_to?(:has_attachment)).to eq(true)
      expect(klass.respond_to?(:build_attachments)).to eq(true)
    end
  end
end
