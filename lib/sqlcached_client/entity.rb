require 'sqlcached_client/hash_struct'
require 'sqlcached_client/resultset'
require 'sqlcached_client/server'

module SqlcachedClient
  class Entity < HashStruct

    attr_reader :count, :resultset, :attributes

    # @param attributes [Hash]
    def initialize(attributes)
      @attributes = attributes.keys
      super(attributes)
    end

    class << self
      attr_reader :query_id

      def entity_name(value)
        @query_id = value
      end

      def query(sql_string = nil)
        sql_string.nil? ? @query : @query = sql_string.strip
      end

      def server(config = nil)
        if config.nil?
          @server ||
            if (superclass = ancestors[1]).respond_to?(:server)
              superclass.server
            else
              nil
            end
        else
          @server =
            if config.is_a?(Hash)
              Server.new(config)
            else
              config
            end
        end
      end

      def where(params)
        Resultset.new(self, server.run_query(query_id, query, params))
      end
    end # class << self

    def to_s
      if respond_to?(:id)
        "#<#{self.class.name}: id: #{id}>"
      else
        super
      end
    end
  end # class Entity
end
