module SqlcachedClient
  class Resultset
    include Enumerable

    attr_reader :entity_class, :entities, :count

    # @param entity_class [Class]
    # @param entities [Array]
    def initialize(entity_class, entities)
      @entity_class = entity_class
      @entities = (entities || []).map { |item| entity_class.new(item) }
      @count = @entities.size
    end

    def each(&block)
      block ? entities.each(&block) : entities.each
    end

    def [](i)
      entities[i]
    end

    def uncache
      # TODO
    end

    def fill_associations(data)
      data.map.with_index do |entity_assoc_data, i|
        entities[i].set_associations_data(entity_assoc_data)
      end
    end

    def get_entities_association_requests
      entities.map do |entity|
        entity.get_association_requests
      end
    end

    def eager_load(max_depth = false)
      self.class.eager_load([self], entity_class.server, max_depth)
    end

    class << self

      def eager_load(resultsets, server, max_depth, current_depth = 0)
        if resultsets.any?
          requests_batch = resultsets.map do |r|
            r.get_entities_association_requests
          end
          if requests_batch.flatten.any?
            next_batch =
              server.run_query(
                server.build_request_body(
                  requests_batch
                )
              ).map.with_index do |resultset_data, i|
                resultsets[i].fill_associations(resultset_data)
              end.flatten!
            if !max_depth || current_depth < max_depth
              eager_load(next_batch, server, max_depth, current_depth + 1)
            end
          end
        end
      end

    end # class << self
  end
end
