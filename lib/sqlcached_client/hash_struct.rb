module SqlcachedClient
  # Maps recursively hashes into objects with lazy evaluation. For example
  #
  #  hs = HashStruct.new({
  #    a: ['foo', { a1: [{ a2: 'one' }, 'two', 'three'] }, 'bar'],
  #    b: 'baz',
  #    c: 4,
  #    d: { d1: { d2: { d3: 'hi' } } }
  #  })
  #    # => #<HashStruct:0x0000000f188008>
  #
  #  hs.b
  #    # => "baz"
  #
  #  hs.c
  #    # => 4
  #
  #  hs.a
  #    # => ["foo", #<HashStruct:0x0000000f1dc798>, "bar"]
  #
  #  hs.a[1].a1
  #    # => [#<HashStruct:0x0000000f275ce0>, "two", "three"]
  #
  #  hs.a[1].a1[0].a2
  #    # => "one"
  #
  #  # values are memoized
  #  hs
  #    # => #<HashStruct:0x0000000f188008
  #    #  @_a=["foo", #<HashStruct:0x0000000f1dc798 @_a1=[#<HashStruct:0x0000000f275ce0 @_a2="one">, "two", "three"]>, "bar"],
  #    #  @_b="baz",
  #    #  @_c=4>
  class HashStruct

    def initialize(hash)
      hash.each do |key, value|
        define_singleton_method(key.to_sym, &HashStruct.build(value, key))
      end
    end

    class << self

      # @return [Proc]
      def build(value, accessor_name = nil)
        lambda =
          if value.is_a?(Hash)
            -> (aself, value) { HashStruct.new(value) }
          elsif value.is_a?(Array)
            -> (aself, value) {
              value.map { |item| aself.instance_eval(&HashStruct.build(item)) }
            }
          else
            -> (aself, value) { value }
          end
        if !accessor_name.nil?
          memoize_v = "@_#{accessor_name}"
          Proc.new {
            if instance_variable_defined?(memoize_v)
              instance_variable_get(memoize_v)
            else
              instance_variable_set(memoize_v, lambda.call(self, value))
            end
          }
        else
          Proc.new { lambda.call(self, value) }
        end
      end
    end # class << self
  end # class HashStruct
end
