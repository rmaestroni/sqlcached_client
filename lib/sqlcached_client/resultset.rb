module SqlcachedClient
  class Resultset
    include Enumerable

    attr_reader :entity_class, :entities, :count

    # @param entity_class [Class]
    # @param data [Array] or [ServerResponse]
    def initialize(entity_class, data, attachments = nil)
      # set entity class
      @entity_class = entity_class
      # build the entities
      ents = data.respond_to?(:entities) ? data.entities : data
      @entities = (ents || []).map do |item|
        if item.is_a?(Hash)
          entity_class.new(item)
        elsif item.is_a?(entity_class)
          item
        else
          raise "Cannot handle: #{item.inspect}"
        end
      end
      # record collection size
      @count = @entities.size
      # set up attachments
      set_entities_attachments(@entities, attachments, data.try(:attachments))
    end

    class << self

      def build_associations(resultsets, server, session, max_depth, current_depth = 0)
        if resultsets.any?
          batch = resultsets.map { |r| r._get_entities_association_requests }
          if batch.flatten.any?
            next_batch =
              server.run_query(
                session,
                server.build_request(
                  batch
                )
              ).map.with_index do |resultset_data, i|
                resultsets[i]._fill_associations(resultset_data)
              end.flatten!
            if !max_depth || current_depth < max_depth
              build_associations(next_batch, server, session, max_depth,
                current_depth + 1)
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

    def build_associations(max_depth = false)
      entity_class.server_session do |server, session|
        self.class.build_associations([self], server, session, max_depth)
      end
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

    def set_entities_attachments(entities, attachments, contents)
      if attachments.is_a?(Array) && contents.is_a?(Array)
        entities.each_with_index do |entity, i|
          attachment = attachments[i]
          entity.send("#{attachment.name}=", attachment)
          attachment.content = contents[i] if attachment.respond_to?(:content=)
        end
      end
    end

    def store_attachments(attachment_name, server, session)
      entities_with_a = entities.select do |entity|
        !entity.send(attachment_name).nil?
      end
      server.store_attachments(
        session,
        server.build_store_attachments_request(
          entities_with_a.map { |e| e.attributes },
          entities_with_a.map { |e| e.send(attachment_name).to_save_format }
        )
      )
    end
  end
end
