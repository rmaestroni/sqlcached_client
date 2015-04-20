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

      def has_many(accessor_name, options)
        foreign_class_name =
          if options[:class_name].present?
            options[:class_name]
          else
            accessor_name.to_s.singularize.camelize
          end
        # get the attributes to define the foreign scope
        join_attributes = (options[:where] || []).to_a
        # define the accessor method
        define_method(accessor_name) do
          # get the associated entity class
          foreign_entity = Module.const_get(foreign_class_name)
          # memoized the associated resultset
          memoize_var = "@has_many_#{accessor_name}"
          instance_variable_get(memoize_var) ||
            instance_variable_set(
              memoize_var,
              foreign_entity.where(Hash[ join_attributes.map do |attr_names|
                attr_value =
                  if attr_names[1].is_a?(Symbol)
                    send(attr_names[1])
                  else
                    attr_names[1]
                  end
                [ attr_names[0], attr_value ]
              end ])
            )
        end
        # save the newly created association
        register_association(accessor_name)
      end

      def has_one(accessor_name, options)
        plural_accessor_name = "s_#{accessor_name}".to_s.pluralize
        class_name = accessor_name.to_s.camelize
        has_many(plural_accessor_name, { class_name: class_name }.merge(options))
        define_method(accessor_name) do
          send(plural_accessor_name).first
        end
      end

      def registered_associations
        @registered_associations || []
      end

    private

      def register_association(association_name)
        @registered_associations ||= []
        @registered_associations << association_name.to_sym
      end
    end # class << self

    def load_associations(load_recursively = false)
      self.class.registered_associations.each do |a_name|
        associated = send(a_name)
        associated.load_associations(true) if load_recursively
        a_name
      end
    end
  end # class Entity
end
