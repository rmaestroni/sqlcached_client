require 'sqlcached_client/resultset'
require 'sqlcached_client/server'
require 'sqlcached_client/arel'
require 'sqlcached_client/tree_visitor'

module SqlcachedClient
  class Entity
    extend Arel
    extend TreeVisitor

    attr_reader :attributes

    # @param attributes [Hash]
    def initialize(attributes)
      @attributes = attributes
      define_readers(attributes.keys)
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
              server.build_request_item(query_id, query, parameter, cache)
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
              server.run_query(session, server.build_request(
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
              if this.join_constant_value?(attr_names[1])
                attr_names[1]
              else
                this.send(attr_names[1])
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
            association.(self, foreign_entity, join_attributes, true)
          else
            instance_variable_get(memoize_var) ||
              instance_variable_set(memoize_var,
                association.(self, foreign_entity, join_attributes, false))
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
        register_association(OpenStruct.new({
          accessor_name: accessor_name.to_sym,
          class_name: foreign_class_name,
          join_attributes: join_attributes
        }))
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


      def association_names
        registered_associations.map(&:accessor_name)
      end


      def is_an_association?(name)
        association_names.include?(name.to_sym)
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


      def build_query_tree
        # returns the subtrees (associated classes) of the given entity class
        get_associated_entities = -> (entity) {
          entity.registered_associations.map do |a|
            Module.const_get(a.class_name)
          end
        }

        # function to apply to each node while traversing the tree
        visit = -> (entity, parent, index) {
          entity.server.build_request_item(
            entity.query_id,
            entity.query,
            # query_params
            if parent
              Hash[
                parent.registered_associations[index].join_attributes.map do |j_attr|
                  [ j_attr[0], {
                    value: j_attr[1],
                    type: begin
                      if entity.join_constant_value?(j_attr[1])
                        'constant'
                      else
                        'parent_attribute'
                      end
                    end
                  } ]
                end
              ]
            else
              nil
            end,
            entity.cache
          ).merge(associations: entity.association_names)
        }

        # builds the result of a visit step
        result_builder = -> (root, subtrees) {
          { root: root, subtrees: subtrees }
        }

        # traverse the tree
        visit_in_preorder(get_associated_entities, visit, result_builder)
      end


      def join_constant_value?(value)
        !value.is_a?(Symbol)
      end

      # Like 'where' but loads every associated entity recursively at any level,
      #   with only one interaction with the server
      # @param root_conditions [Array]
      def load_tree(root_conditions)
        server.session do |server, session|
          Resultset.new(
            self,
            server.run_query(
              session,
              server.build_tree_request(build_query_tree, root_conditions)
            )
          )
        end
      end

    private

      def register_association(association_struct)
        @registered_associations ||= []
        @registered_associations << association_struct
      end
    end # class << self

    # Define the readers for the attribute names specified
    # @param attr_names [Array]
    def define_readers(attr_names)
      attr_names.each do |attr_name|
        if respond_to?(attr_name)
          if self.class.is_an_association?(attr_name)
            # lazy instantiate associated records
            association_writer = method("#{attr_name}=")
            association_reader = method(attr_name)
            define_singleton_method(attr_name) do
              association_writer.(attributes[attr_name])
              association_reader.()
            end
          else
            raise "Cannot define accessor: #{attr_name}"
          end
        else
          define_singleton_method(attr_name) do
            attributes[attr_name]
          end
        end
      end
    end


    def join_constant_value?(value)
      self.class.join_constant_value?(value)
    end


    def get_association_requests
      self.class.association_names.map do |a_name|
        send(a_name, true)
      end
    end


    def set_associations_data(associations_data)
      self.class.association_names.map.with_index do |a_name, i|
        send("#{a_name}=", associations_data[i])
      end
    end


    def get_associations
      self.class.association_names.map do |a_name|
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
