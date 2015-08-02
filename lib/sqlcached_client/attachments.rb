require 'sqlcached_client/attachment'

module SqlcachedClient
  module Attachments

    module ClassMethods

      def has_attachment(name, &block)
        @attachment_classes ||= {}
        @attachment_classes[name] =
          Class.new(Attachment) do

            @attachment_name = name
            class << self
              attr_reader :attachment_name
            end

            def initialize(conditions, content)
              super(self.class.attachment_name, conditions, content)
            end

            instance_exec(&block)
          end
        attr_accessor(name)
      end

      def build_attachments(name, conditions, size)
        size.times.map { @attachment_classes[name].new(conditions, nil) }
      end
    end # module ClassMethods

    def self.included(base)
      base.extend ClassMethods
    end
  end
end
