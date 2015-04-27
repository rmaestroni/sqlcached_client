module SqlcachedClient
  class Resultset
    include Enumerable

    attr_reader :entity_class, :entities, :count

    # @param entity_class [Class]
    # @param entities [Array]
    def initialize(entity_class, entities)
      @entity_class = entity_class
      @entities = (entities || []).map do |item|
        if item.is_a?(Hash)
          entity_class.new(item)
        elsif item.is_a?(entity_class)
          item
        else
          raise "Cannot handle instances of #{item.class.name}"
        end
      end
      @count = @entities.size
    end

    class << self

      def build_associations(resultsets, server, max_depth, current_depth = 0)
        if resultsets.any?
          batch = resultsets.map { |r| r._get_entities_association_requests }
          if batch.flatten.any?
            next_batch =
              server.run_query(
                server.build_request_body(
                  batch
                )
              ).map.with_index do |resultset_data, i|
                resultsets[i]._fill_associations(resultset_data)
              end.flatten!
            if !max_depth || current_depth < max_depth
              build_associations(next_batch, server, max_depth, current_depth + 1)
            end
          end
        end
      end
    end # class << self

    def each(&block)
      block ? entities.each(&block) : entities.each
    end

    def [](i)
      entities[i]
    end

    def uncache
      # TODO
    end

    def build_associations(max_depth = false)
      self.class.build_associations([self], entity_class.server, max_depth)
    end

    def _fill_associations(data)
      data.map.with_index do |entity_assoc_data, i|
        entities[i].set_associations_data(entity_assoc_data)
      end
    end

    def _get_entities_association_requests
      entities.map do |entity|
        entity.get_association_requests
      end
    end
  end
end
