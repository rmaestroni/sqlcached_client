require 'active_support/core_ext/hash'

module SqlcachedClient
  class Attachment

    PREDICATES = ['=', '<=', '>']

    attr_reader :name, :conditions
    attr_accessor :content

    # @param conditions [Hash] { var_1: 'value 1', var_2: 'value 2' }
    def initialize(name, conditions, content)
      @name = name
      @conditions = conditions.with_indifferent_access
      @content = content
    end

    class << self

      attr_reader :variables

      def add_variable(variable_name, predicate)
        raise "Invalid predicate" if !PREDICATES.include?(predicate)
        @variables = [] if @variables.nil?
        @variables << OpenStruct.new(name: variable_name, predicate: predicate)
      end

      alias_method :depends_on, :add_variable
    end # class << self

    def variables
      self.class.variables
    end

    def to_query_format
      {
        name: name,
        condition_values: Hash[
          variables.map { |v| [v.name, conditions[v.name]] }
        ]
      }
    end

    def to_save_format
      {
        name: name,
        attachment: content,
        conditions: variables.map do |v|
          "#{v.name} #{v.predicate} #{conditions[v.name]}"
        end
      }
    end
  end
end
