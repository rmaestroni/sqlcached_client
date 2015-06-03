require 'sqlcached_client/resultset'
require 'sqlcached_client/server'
require 'sqlcached_client/arel'

module SqlcachedClient
  class Entity
    extend Arel

    attr_reader :attributes

    # @param attributes [Hash]
    def initialize(attributes)
      @attributes = attributes
      self.class.define_readers(attributes.keys)
    end


    class << self
      attr_reader :query_id

      # Sets the name of this entity
      def entity_name(value)
        @query_id = value
      end

      # Sets the query of this entity if a parameter is provided, otherwise
      # returns the value previously set.
      def query(*args, &block)
        if args.empty?
          @query
        else
          if args[0].is_a?(String)
            @query = args[0].strip
          else
            @query = build_arel(
              args.inject({}) do |acc, param|
                acc.merge(
                  param.is_a?(Hash) ? param : Hash[ [[param, nil]] ]
                )
              end,
              block).to_sql
          end
        end
      end

      # Configures the server of this entity if a parameter is provided,
      # otherwise returns the server object previously set.
      def server(config = nil)
        if config.nil?
          @server ||
            if superclass = ancestors[1..-1].detect { |a| a.respond_to?(:server) }
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

      # Gets a session from the server and yields the passed block
      def server_session(&block)
        server.session(&block)
      end

      # Runs the entity query with the provided parameters
      # @return [Resultset]
      def where(params, dry_run = false)
        request =
          begin
            paramIterator = -> (parameter) {
              server.format_request(query_id, query, parameter, cache)
            }
            if params.is_a?(Array)
              params.map { |p| instance_exec(p, &paramIterator) }
            else
              instance_exec(params, &paramIterator)
            end
          end
        if dry_run
          request
        else
          data =
            server.session do |server, session|
              server.run_query(session, server.build_request_body(
                request.is_a?(Array) ? request : [request]
              ))
            end
          data.flatten!(1) if data.is_a?(Array)
          Resultset.new(self, data)
        end
      end

      # Defines a 'has_many' relationship. Available options are
      # [class_name]
      #   Specifies the class of the associated objects, if not given it's
      #   inferred from the accessor_name (singularized + camelized).
      # [where]
      #   Specifies how to fill the query template for the associated objects.
      #   It's an hash where each key is a foreign parameter that will be
      #   set to the value provided. A special case occours when the value is
      #   a Symbol, in this case it represents the value of the attribute named
      #   as the symbol.
      #   For example, <tt>where: { id: :user_id }</tt> fills the parameter
      #   <tt>id</tt> of the foreign entity with the value of
      #   <tt>self.user_id</tt>.
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
        # memoize the associated resultset
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

      # Defines a 'has_one' relationship. See 'has_many' for the available
      # options
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

      # Define the readers for the attribute names specified
      # @param attr_names [Array]
      def define_readers(attr_names)
        if @_readers_defined.nil?
          attr_names.each do |attr_name|
            if method_defined?(attr_name)
              raise "Cannot define accessor: #{attr_name}"
            else
              define_method(attr_name) do
                attributes[attr_name]
              end
            end
          end
          @_readers_defined = true
        end
      end

      # Configures the caching timing if a parameter is provided, otherwise
      # returns the value set in the current class or in a superclass.
      # Default value is true.
      def cache(seconds = nil)
        if seconds.nil?
          @cache ||
            if superclass = ancestors[1..-1].detect { |a| a.respond_to?(:cache) }
              superclass.cache
            else
              true
            end
        else
          @cache = seconds
        end
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
      end
    end

    def get_associations
      self.class.registered_associations.map do |a_name|
        send(a_name)
      end
    end

    def build_associations(max_depth = false)
      Resultset.new(self.class, [self]).build_associations(max_depth)
    end

    def to_h
      attributes
    end

  end # class Entity
end
