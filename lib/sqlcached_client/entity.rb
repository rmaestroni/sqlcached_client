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

      def where(params, dry_run = false)
        request = server.format_request(query_id, query, params)
        if dry_run
          request
        else
          data = server.run_query(server.build_request_body([request]))
          data = data[0] if data.is_a?(Array)
          Resultset.new(self, data)
        end
      end

      def has_many(accessor_name, options)
        foreign_class_name =
          if options[:class_name].present?
            options[:class_name]
          else
            accessor_name.to_s.singularize.camelize
          end
        # the query to run to get the data
        association = -> (this, foreign_entity, join_attributes, dry_run) {
          foreign_entity.where(Hash[ join_attributes.map do |attr_names|
            attr_value =
              if attr_names[1].is_a?(Symbol)
                this.send(attr_names[1])
              else
                attr_names[1]
              end
            [ attr_names[0], attr_value ]
          end ], dry_run)
        }
        # get the attributes to define the foreign scope
        join_attributes = (options[:where] || []).to_a
        # memoized the associated resultset
        memoize_var = "@has_many_#{accessor_name}"
        # define the accessor method
        define_method(accessor_name) do |dry_run = false|
          # get the associated entity class
          foreign_entity = Module.const_get(foreign_class_name)
          if dry_run
            association.call(self, foreign_entity, join_attributes, true)
          else
            instance_variable_get(memoize_var) ||
              instance_variable_set(memoize_var,
                association.call(self, foreign_entity, join_attributes, false))
          end
        end
        # define the setter method
        define_method("#{accessor_name}=") do |array|
          # get the associated entity class
          foreign_entity = Module.const_get(foreign_class_name)
          instance_variable_set(memoize_var,
            Resultset.new(foreign_entity, array))
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

    def get_association_requests
      self.class.registered_associations.map do |a_name|
        send(a_name, true)
      end
    end

    def set_associations_data(associations_data)
      self.class.registered_associations.map.with_index do |a_name, i|
        send("#{a_name}=", associations_data[i])
        a_name
      end
    end

    def load_associations(load_recursively = false)
      klass = self.class
      data = klass.server.run_query(
        klass.server.build_request_body(
          get_association_requests))
      # set each association
      associations = set_associations_data(data)
      if load_recursively
        associations.map do |a_name|
          send(a_name).load_associations(true)
          a_name
        end
      else
        associations
      end
    end

  end # class Entity
end
