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

    def uncache
      # TODO
    end

    def load_associations(load_recursively = false)
      data = entity_class.server.run_query(
        entity_class.server.build_request_body(
          resultset.map do |entity|
            entity.get_association_requests
          end ))
      data.map.with_index do |entity_assoc_data, i|
        resultset[i].set_associations_data(entity_assoc_data)
        resultset[i].load_associations(true) if load_recursively
        resultset[i]
      end
    end
  end
end
