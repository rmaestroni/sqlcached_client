require 'sqlcached_client/hash_struct'

RSpec.describe SqlcachedClient::HashStruct do
  let(:hash_struct) do
    SqlcachedClient::HashStruct.new({
      a: ['foo', { a1: [{ a2: 'one' }, 'two', 'three'] }, 'bar'],
      b: 'baz',
      c: 4,
      d: { d1: { d2: { d3: 'hi' } } }
    })
  end

  it "should map keys into methods" do
    [:a, :b, :c, :d].each do |m|
      expect(hash_struct.respond_to?(m)).to eq(true)
    end
  end

  it "should map recoursively" do
    ary = hash_struct.a
    expect(ary[0]).to eq('foo')
    expect(ary[1].a1[0].a2).to eq('one')
    expect(hash_struct.d.d1.d2.d3).to eq('hi')
    expect(hash_struct.c).to eq(4)
  end
end
