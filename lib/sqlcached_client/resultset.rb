module SqlcachedClient
  class Resultset
    include Enumerable

    attr_reader :entity_class, :resultset, :count

    # @param entity_class [Class]
    # @param resultset [Array]
    def initialize(entity_class, resultset)
      @entity_class = entity_class
      @resultset = (resultset || []).map { |item| entity_class.new(item) }
      @count = @resultset.size
    end

    def each(&block)
      block ? resultset.each(&block) : resultset.each
    end

    def [](i)
      resultset[i]
    end
  end
end
