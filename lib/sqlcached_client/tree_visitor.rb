module SqlcachedClient
  module TreeVisitor

    # @param get_subtrees [Proc]
    # @param visit [Proc]
    # @param result_builder [Proc]
    # @param parent [Object]
    # @param index [Integer]
    def visit_in_preorder(get_subtrees, visit, result_builder,
        parent = nil, index = nil)
      result_builder.(
        visit.(self, parent, index),
        get_subtrees.(self).map.with_index do |item, i|
          item.visit_in_preorder(get_subtrees, visit, result_builder, self, i)
        end
      )
    end
  end
end
