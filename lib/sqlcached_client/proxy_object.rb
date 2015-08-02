module SqlcachedClient
  class ProxyObject < BasicObject

    def initialize(context)
      @context = context
    end

    def method_missing(symbol, *args)
      @context.send(symbol, *args)
    end

    def execute(*args, &block)
      instance_exec(*args, &block)
    end

    def plug_method(method_name, &method_body)
      memoize_var = "@m_#{method_name}"
      instance_variable_set(memoize_var, method_body)
      eval(
        <<-RUBY
          def self.#{method_name}(*args, &block)
            instance_exec(*args, block, &#{memoize_var})
          end
        RUBY
      )
      method_name.to_sym
    end
  end
end
