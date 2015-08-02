module SqlcachedClient
  module ServerResponses

    class QueryResponse
      include Enumerable

      attr_reader :body

      # @param body [Hash]
      def initialize(body)
        @body = body
      end

      def each(&block)
        block ? entities.each(&block) : entities.each
      end

      def attachments
        body.is_a?(Hash) ? body['attachments'] : nil
      end

      def entities
        @entities ||= get_entities(body)
      end

      def is_array?
        entities.is_a?(Array)
      end

      def flatten!(level = nil)
        entities if @entities.nil?
        @entities.flatten!(level)
      end

    private

      def get_entities(data)
        if data.is_a?(Array)
          data.map { |item| get_entities(item) }
        elsif data.is_a?(Hash)
          if (resultset = data['resultset']).is_a?(String)
            JSON.parse(resultset)
          else
            resultset
          end
        else
          data
        end
      end
    end # class QueryResponse
  end
end
