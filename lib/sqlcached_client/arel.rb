require 'singleton'
require 'arel'
require 'active_record'
require 'nulldb'

module SqlcachedClient
  module Arel

    # Builds a SQL query executing the Arel statements in the given block.
    # @param tables_map [Hash] in the form of
    #   { :t1 => [:par1, :par2], :t2 => :par3, :t3 => nil }
    # @param arel_block [Proc]
    # @return [Arel] an object that responds to 'to_sql'
    def build_arel(tables_map, arel_block)
      table_names = tables_map.keys
      # attributes of this struct returns Arel tables named as the attribute
      context = Struct.new(*table_names).new(
        *table_names.map do |t_name|
          ArelWrapper.arel_module::Table.new(t_name)
        end
      )
      # build an Arel object evaluating the block if any
      arel_q =
        if arel_block
          context.instance_eval(&arel_block)
        else
          # no block given, add the default SELECT *
          context.send(tables_map.keys.first).project(
            ArelWrapper.arel_module.sql('*'))
        end
      # add the 'where' conditions passed as parameters (values in tables_map)
      tables_map.inject(arel_q) do |query_acc, item|
        t_name, parameters = item
        table = context.send(t_name)
        parameters ||= []
        parameters = [parameters] if !parameters.respond_to?(:inject)
        parameters.inject(query_acc) do |arel, param|
          arel.where(table[param].eq("{{ #{param} }}"))
        end
      end
    end # method build_arel
  end # module Arel

private

  class ArelWrapper
    include Singleton

    def initialize
      ::Arel::Table.engine = ::ActiveRecord::Base.establish_connection(
        adapter: :nulldb)
    end

    class << self
      def arel_module
        instance
        ::Arel
      end
    end
  end # class ArelWrapper
end
